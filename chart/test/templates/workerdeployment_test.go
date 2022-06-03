package main

import (
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
	appsV1 "k8s.io/api/apps/v1"
	coreV1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func TestWorkerDeploymentTemplate(t *testing.T) {
	for _, tc := range []struct {
		CaseName string
		Release  string
		Values   map[string]string

		ExpectedErrorRegexp *regexp.Regexp

		ExpectedName        string
		ExpectedRelease     string
		ExpectedDeployments []workerDeploymentTestCase
	}{
		{
			CaseName: "happy",
			Release:  "production",
			Values: map[string]string{
				"releaseOverride":            "productionOverridden",
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
				"workers.worker2.command[0]": "echo",
				"workers.worker2.command[1]": "worker2",
			},
			ExpectedName:    "productionOverridden",
			ExpectedRelease: "production",
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:         "productionOverridden-worker1",
					ExpectedCmd:          []string{"echo", "worker1"},
					ExpectedStrategyType: appsV1.DeploymentStrategyType(""),
				},
				{
					ExpectedName:         "productionOverridden-worker2",
					ExpectedCmd:          []string{"echo", "worker2"},
					ExpectedStrategyType: appsV1.DeploymentStrategyType(""),
				},
			},
		}, {
			// See https://github.com/helm/helm/issues/6006
			CaseName: "long release name",
			Release:  strings.Repeat("r", 80),

			ExpectedErrorRegexp: regexp.MustCompile("Error: release name .* exceeds max length of 53"),
		},
		{
			CaseName: "strategyType",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":   "echo",
				"workers.worker1.command[1]":   "worker1",
				"workers.worker1.strategyType": "Recreate",
			},
			ExpectedName:    "production",
			ExpectedRelease: "production",
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:         "production" + "-worker1",
					ExpectedCmd:          []string{"echo", "worker1"},
					ExpectedStrategyType: appsV1.RecreateDeploymentStrategyType,
				},
			},
		},
		{
			CaseName: "nodeSelector",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":            "echo",
				"workers.worker1.command[1]":            "worker1",
				"workers.worker1.nodeSelector.disktype": "ssd",
			},
			ExpectedName:    "production",
			ExpectedRelease: "production",
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:         "production" + "-worker1",
					ExpectedCmd:          []string{"echo", "worker1"},
					ExpectedStrategyType: appsV1.DeploymentStrategyType(""),
					ExpectedNodeSelector: map[string]string{"disktype": "ssd"},
				},
			},
		},
		{
			CaseName: "tolerations",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":              "echo",
				"workers.worker1.command[1]":              "worker1",
				"workers.worker1.tolerations[0].key":      "key1",
				"workers.worker1.tolerations[0].operator": "Equal",
				"workers.worker1.tolerations[0].value":    "value1",
				"workers.worker1.tolerations[0].effect":   "NoSchedule",
			},
			ExpectedName:    "production",
			ExpectedRelease: "production",
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:         "production" + "-worker1",
					ExpectedCmd:          []string{"echo", "worker1"},
					ExpectedStrategyType: appsV1.DeploymentStrategyType(""),
					ExpectedTolerations: []coreV1.Toleration{
						{
							Key:      "key1",
							Operator: "Equal",
							Value:    "value1",
							Effect:   "NoSchedule",
						},
					},
				},
			},
		},
		{
			CaseName: "initContainers",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":                   "echo",
				"workers.worker1.command[1]":                   "worker1",
				"workers.worker1.initContainers[0].name":       "myservice",
				"workers.worker1.initContainers[0].image":      "myimage:1",
				"workers.worker1.initContainers[0].command[0]": "sh",
				"workers.worker1.initContainers[0].command[1]": "-c",
				"workers.worker1.initContainers[0].command[2]": "until nslookup myservice; do echo waiting for myservice to start; sleep 1; done;",
			},
			ExpectedName:    "production",
			ExpectedRelease: "production",
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:         "production" + "-worker1",
					ExpectedCmd:          []string{"echo", "worker1"},
					ExpectedStrategyType: appsV1.DeploymentStrategyType(""),
					ExpectedInitContainers: []coreV1.Container{
						{
							Name:    "myservice",
							Image:   "myimage:1",
							Command: []string{"sh", "-c", "until nslookup myservice; do echo waiting for myservice to start; sleep 1; done;"},
						},
					},
				},
			},
		},
		{
			CaseName: "affinity",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
				"workers.worker1.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key":      "key1",
				"workers.worker1.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator": "DoesNotExist",
			},
			ExpectedName:    "production",
			ExpectedRelease: "production",
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:         "production" + "-worker1",
					ExpectedCmd:          []string{"echo", "worker1"},
					ExpectedStrategyType: appsV1.DeploymentStrategyType(""),
					ExpectedAffinity: &coreV1.Affinity{
						NodeAffinity: &coreV1.NodeAffinity{
							RequiredDuringSchedulingIgnoredDuringExecution: &coreV1.NodeSelector{
								NodeSelectorTerms: []coreV1.NodeSelectorTerm{
									{
										MatchExpressions: []coreV1.NodeSelectorRequirement{
											{
												Key:      "key1",
												Operator: "DoesNotExist",
											},
										},
									},
								},
							},
						},
					},
				},
			},
		},
	} {
		t.Run(tc.CaseName, func(t *testing.T) {
			namespaceName := "minimal-ruby-app-" + strings.ToLower(random.UniqueId())

			values := map[string]string{
				"gitlab.app": "auto-devops-examples/minimal-ruby-app",
				"gitlab.env": "prod",
			}

			mergeStringMap(values, tc.Values)

			options := &helm.Options{
				SetValues:      values,
				KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
			}

			output, err := helm.RenderTemplateE(t, options, helmChartPath, tc.Release, []string{"templates/worker-deployment.yaml"})

			if tc.ExpectedErrorRegexp != nil {
				require.Regexp(t, tc.ExpectedErrorRegexp, err.Error())
				return
			}
			if err != nil {
				t.Error(err)
				return
			}

			var deployments deploymentList
			helm.UnmarshalK8SYaml(t, output, &deployments)

			require.Len(t, deployments.Items, len(tc.ExpectedDeployments))
			for i, expectedDeployment := range tc.ExpectedDeployments {
				deployment := deployments.Items[i]

				require.Equal(t, expectedDeployment.ExpectedName, deployment.Name)
				require.Equal(t, expectedDeployment.ExpectedStrategyType, deployment.Spec.Strategy.Type)

				require.Equal(t, map[string]string{
					"app.gitlab.com/app": "auto-devops-examples/minimal-ruby-app",
					"app.gitlab.com/env": "prod",
				}, deployment.Annotations)
				require.Equal(t, map[string]string{
					"chart":    chartName,
					"heritage": "Helm",
					"release":  tc.ExpectedRelease,
					"tier":     "worker",
					"track":    "stable",
				}, deployment.Labels)

				require.Equal(t, map[string]string{
					"app.gitlab.com/app":           "auto-devops-examples/minimal-ruby-app",
					"app.gitlab.com/env":           "prod",
					"checksum/application-secrets": "",
				}, deployment.Spec.Template.Annotations)
				require.Equal(t, map[string]string{
					"release": tc.ExpectedRelease,
					"tier":    "worker",
					"track":   "stable",
				}, deployment.Spec.Template.Labels)

				require.Len(t, deployment.Spec.Template.Spec.Containers, 1)
				require.Equal(t, expectedDeployment.ExpectedCmd, deployment.Spec.Template.Spec.Containers[0].Command)

				require.Equal(t, expectedDeployment.ExpectedNodeSelector, deployment.Spec.Template.Spec.NodeSelector)
				require.Equal(t, expectedDeployment.ExpectedTolerations, deployment.Spec.Template.Spec.Tolerations)
				require.Equal(t, expectedDeployment.ExpectedInitContainers, deployment.Spec.Template.Spec.InitContainers)
				require.Equal(t, expectedDeployment.ExpectedAffinity, deployment.Spec.Template.Spec.Affinity)
			}
		})
	}

	// Tests worker selector
	for _, tc := range []struct {
		CaseName string
		Release  string
		Values   map[string]string

		ExpectedName        string
		ExpectedRelease     string
		ExpectedDeployments []workerDeploymentSelectorTestCase
	}{
		{
			CaseName: "worker selector",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
				"workers.worker2.command[0]": "echo",
				"workers.worker2.command[1]": "worker2",
			},
			ExpectedName:    "production",
			ExpectedRelease: "production",
			ExpectedDeployments: []workerDeploymentSelectorTestCase{
				{
					ExpectedName: "production-worker1",
					ExpectedSelector: &metav1.LabelSelector{
						MatchLabels: map[string]string{
							"release": "production",
							"tier":    "worker",
							"track":   "stable",
						},
					},
				},
				{
					ExpectedName: "production-worker2",
					ExpectedSelector: &metav1.LabelSelector{
						MatchLabels: map[string]string{
							"release": "production",
							"tier":    "worker",
							"track":   "stable",
						},
					},
				},
			},
		},
	} {
		t.Run(tc.CaseName, func(t *testing.T) {
			namespaceName := "minimal-ruby-app-" + strings.ToLower(random.UniqueId())

			values := map[string]string{
				"gitlab.app": "auto-devops-examples/minimal-ruby-app",
				"gitlab.env": "prod",
			}

			mergeStringMap(values, tc.Values)

			options := &helm.Options{
				SetValues:      values,
				KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
			}

			output := helm.RenderTemplate(t, options, helmChartPath, tc.Release, []string{"templates/worker-deployment.yaml"})

			var deployments deploymentAppsV1List
			helm.UnmarshalK8SYaml(t, output, &deployments)

			require.Len(t, deployments.Items, len(tc.ExpectedDeployments))
			for i, expectedDeployment := range tc.ExpectedDeployments {
				deployment := deployments.Items[i]

				require.Equal(t, expectedDeployment.ExpectedName, deployment.Name)

				require.Equal(t, map[string]string{
					"chart":    chartName,
					"heritage": "Helm",
					"release":  tc.ExpectedRelease,
					"tier":     "worker",
					"track":    "stable",
				}, deployment.Labels)

				require.Equal(t, expectedDeployment.ExpectedSelector, deployment.Spec.Selector)

				require.Equal(t, map[string]string{
					"release": tc.ExpectedRelease,
					"tier":    "worker",
					"track":   "stable",
				}, deployment.Spec.Template.Labels)
			}
		})
	}

	// serviceAccountName
	for _, tc := range []struct {
		CaseName string
		Release  string
		Values   map[string]string

		ExpectedDeployments []workerDeploymentServiceAccountTestCase
	}{
		{
			CaseName: "default service account",
			Release:  "production",
			ExpectedDeployments: []workerDeploymentServiceAccountTestCase{
				{
					ExpectedServiceAccountName: "",
				},
			},
		},
		{
			CaseName: "empty service account name",
			Release:  "production",
			Values: map[string]string{
				"serviceAccountName": "",
			},
			ExpectedDeployments: []workerDeploymentServiceAccountTestCase{
				{
					ExpectedServiceAccountName: "",
				},
			},
		},
		{
			CaseName: "custom service account name - myServiceAccount",
			Release:  "production",
			Values: map[string]string{
				"serviceAccountName": "myServiceAccount",
			},
			ExpectedDeployments: []workerDeploymentServiceAccountTestCase{
				{
					ExpectedServiceAccountName: "myServiceAccount",
				},
			},
		},
	} {
		t.Run(tc.CaseName, func(t *testing.T) {
			namespaceName := "minimal-ruby-app-" + strings.ToLower(random.UniqueId())

			values := map[string]string{
				"gitlab.app":                 "auto-devops-examples/minimal-ruby-app",
				"gitlab.env":                 "prod",
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
			}

			mergeStringMap(values, tc.Values)

			options := &helm.Options{
				SetValues:      values,
				KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
			}

			output := helm.RenderTemplate(t, options, helmChartPath, tc.Release, []string{"templates/worker-deployment.yaml"})

			var deployments deploymentAppsV1List
			helm.UnmarshalK8SYaml(t, output, &deployments)

			require.Len(t, deployments.Items, len(tc.ExpectedDeployments))

			for i, expectedDeployment := range tc.ExpectedDeployments {
				deployment := deployments.Items[i]
				require.Equal(t, expectedDeployment.ExpectedServiceAccountName, deployment.Spec.Template.Spec.ServiceAccountName)
			}
		})
	}

	// serviceAccount
	for _, tc := range []struct {
		CaseName string
		Release  string
		Values   map[string]string

		ExpectedDeployments []workerDeploymentServiceAccountTestCase
	}{
		{
			CaseName: "default service account",
			Release:  "production",
			ExpectedDeployments: []workerDeploymentServiceAccountTestCase{
				{
					ExpectedServiceAccountName: "",
				},
			},
		},
		{
			CaseName: "empty service account name",
			Release:  "production",
			Values: map[string]string{
				"serviceAccount.name": "",
			},
			ExpectedDeployments: []workerDeploymentServiceAccountTestCase{
				{
					ExpectedServiceAccountName: "",
				},
			},
		},
		{
			CaseName: "custom service account name - myServiceAccount",
			Release:  "production",
			Values: map[string]string{
				"serviceAccount.name": "myServiceAccount",
			},
			ExpectedDeployments: []workerDeploymentServiceAccountTestCase{
				{
					ExpectedServiceAccountName: "myServiceAccount",
				},
			},
		},
		{
			CaseName: "serviceAccount.name takes precedence over serviceAccountName",
			Release:  "production",
			Values: map[string]string{
				"serviceAccount.name": "myServiceAccount1",
				"serviceAccountName":  "myServiceAccount2",
			},
			ExpectedDeployments: []workerDeploymentServiceAccountTestCase{
				{
					ExpectedServiceAccountName: "myServiceAccount1",
				},
			},
		},
	} {
		t.Run(tc.CaseName, func(t *testing.T) {
			namespaceName := "minimal-ruby-app-" + strings.ToLower(random.UniqueId())

			values := map[string]string{
				"gitlab.app":                 "auto-devops-examples/minimal-ruby-app",
				"gitlab.env":                 "prod",
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
			}

			mergeStringMap(values, tc.Values)

			options := &helm.Options{
				SetValues:      values,
				KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
			}

			output := helm.RenderTemplate(
				t,
				options,
				helmChartPath,
				tc.Release,
				[]string{"templates/worker-deployment.yaml"},
			)

			var deployments deploymentAppsV1List
			helm.UnmarshalK8SYaml(t, output, &deployments)

			require.Len(t, deployments.Items, len(tc.ExpectedDeployments))

			for i, expectedDeployment := range tc.ExpectedDeployments {
				deployment := deployments.Items[i]
				require.Equal(
					t,
					expectedDeployment.ExpectedServiceAccountName,
					deployment.Spec.Template.Spec.ServiceAccountName,
				)
			}
		})
	}

	// worker lifecycle
	for _, tc := range []struct {
		CaseName string
		Values   map[string]string
		Release  string

		ExpectedDeployments []workerDeploymentTestCase
	}{
		{
			CaseName: "lifecycle",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":                        "echo",
				"workers.worker1.command[1]":                        "worker1",
				"workers.worker1.lifecycle.preStop.exec.command[0]": "/bin/sh",
				"workers.worker1.lifecycle.preStop.exec.command[1]": "-c",
				"workers.worker1.lifecycle.preStop.exec.command[2]": "sleep 10",
				"workers.worker2.command[0]":                        "echo",
				"workers.worker2.command[1]":                        "worker2",
				"workers.worker2.lifecycle.preStop.exec.command[0]": "/bin/sh",
				"workers.worker2.lifecycle.preStop.exec.command[1]": "-c",
				"workers.worker2.lifecycle.preStop.exec.command[2]": "sleep 15",
			},
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName: "production-worker1",
					ExpectedCmd:  []string{"echo", "worker1"},
					ExpectedLifecycle: &coreV1.Lifecycle{
						PreStop: &coreV1.Handler{
							Exec: &coreV1.ExecAction{
								Command: []string{"/bin/sh", "-c", "sleep 10"},
							},
						},
					},
				},
				{
					ExpectedName: "production-worker2",
					ExpectedCmd:  []string{"echo", "worker2"},
					ExpectedLifecycle: &coreV1.Lifecycle{
						PreStop: &coreV1.Handler{
							Exec: &coreV1.ExecAction{
								Command: []string{"/bin/sh", "-c", "sleep 15"},
							},
						},
					},
				},
			},
		},
		{
			CaseName: "preStopCommand",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":        "echo",
				"workers.worker1.command[1]":        "worker1",
				"workers.worker1.preStopCommand[0]": "/bin/sh",
				"workers.worker1.preStopCommand[1]": "-c",
				"workers.worker1.preStopCommand[2]": "sleep 10",
				"workers.worker2.command[0]":        "echo",
				"workers.worker2.command[1]":        "worker2",
				"workers.worker2.preStopCommand[0]": "/bin/sh",
				"workers.worker2.preStopCommand[1]": "-c",
				"workers.worker2.preStopCommand[2]": "sleep 15",
			},
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName: "production-worker1",
					ExpectedCmd:  []string{"echo", "worker1"},
					ExpectedLifecycle: &coreV1.Lifecycle{
						PreStop: &coreV1.Handler{
							Exec: &coreV1.ExecAction{
								Command: []string{"/bin/sh", "-c", "sleep 10"},
							},
						},
					},
				},
				{
					ExpectedName: "production-worker2",
					ExpectedCmd:  []string{"echo", "worker2"},
					ExpectedLifecycle: &coreV1.Lifecycle{
						PreStop: &coreV1.Handler{
							Exec: &coreV1.ExecAction{
								Command: []string{"/bin/sh", "-c", "sleep 15"},
							},
						},
					},
				},
			},
		},
	} {
		t.Run(tc.CaseName, func(t *testing.T) {
			namespaceName := "minimal-ruby-app-" + strings.ToLower(random.UniqueId())

			values := map[string]string{
				"gitlab.app": "auto-devops-examples/minimal-ruby-app",
				"gitlab.env": "prod",
			}

			mergeStringMap(values, tc.Values)

			options := &helm.Options{
				SetValues:      values,
				KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
			}

			output := helm.RenderTemplate(t, options, helmChartPath, tc.Release, []string{"templates/worker-deployment.yaml"})

			var deployments deploymentAppsV1List
			helm.UnmarshalK8SYaml(t, output, &deployments)

			require.Len(t, deployments.Items, len(tc.ExpectedDeployments))

			for i, expectedDeployment := range tc.ExpectedDeployments {
				deployment := deployments.Items[i]
				require.Equal(t, expectedDeployment.ExpectedName, deployment.Name)
				require.Len(t, deployment.Spec.Template.Spec.Containers, 1)
				require.Equal(t, expectedDeployment.ExpectedCmd, deployment.Spec.Template.Spec.Containers[0].Command)
				require.Equal(t, expectedDeployment.ExpectedLifecycle, deployment.Spec.Template.Spec.Containers[0].Lifecycle)
			}
		})
	}

	// worker livenessProbe, and readinessProbe tests
	for _, tc := range []struct {
		CaseName string
		Values   map[string]string
		Release  string

		ExpectedDeployments []workerDeploymentTestCase
	}{
		{
			CaseName: "default liveness and readiness values",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
				"workers.worker2.command[0]": "echo",
				"workers.worker2.command[1]": "worker2",
			},
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:           "production-worker1",
					ExpectedCmd:            []string{"echo", "worker1"},
					ExpectedLivenessProbe:  defaultLivenessProbe(),
					ExpectedReadinessProbe: defaultReadinessProbe(),
				},
				{
					ExpectedName:           "production-worker2",
					ExpectedCmd:            []string{"echo", "worker2"},
					ExpectedLivenessProbe:  defaultLivenessProbe(),
					ExpectedReadinessProbe: defaultReadinessProbe(),
				},
			},
		},
		{
			CaseName: "enableWorkerLivenessProbe",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":              "echo",
				"workers.worker1.command[1]":              "worker1",
				"workers.worker1.livenessProbe.path":      "/worker",
				"workers.worker1.livenessProbe.scheme":    "HTTP",
				"workers.worker1.livenessProbe.probeType": "httpGet",
				"workers.worker2.command[0]":              "echo",
				"workers.worker2.command[1]":              "worker2",
				"workers.worker2.livenessProbe.path":      "/worker",
				"workers.worker2.livenessProbe.scheme":    "HTTP",
				"workers.worker2.livenessProbe.probeType": "httpGet",
			},
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:           "production-worker1",
					ExpectedCmd:            []string{"echo", "worker1"},
					ExpectedLivenessProbe:  workerLivenessProbe(),
					ExpectedReadinessProbe: defaultReadinessProbe(),
				},
				{
					ExpectedName:           "production-worker2",
					ExpectedCmd:            []string{"echo", "worker2"},
					ExpectedLivenessProbe:  workerLivenessProbe(),
					ExpectedReadinessProbe: defaultReadinessProbe(),
				},
			},
		},
		{
			CaseName: "enableWorkerReadinessProbe",
			Release:  "production",
			Values: map[string]string{
				"workers.worker1.command[0]":               "echo",
				"workers.worker1.command[1]":               "worker1",
				"workers.worker1.readinessProbe.path":      "/worker",
				"workers.worker1.readinessProbe.scheme":    "HTTP",
				"workers.worker1.readinessProbe.probeType": "httpGet",
				"workers.worker2.command[0]":               "echo",
				"workers.worker2.command[1]":               "worker2",
				"workers.worker2.readinessProbe.path":      "/worker",
				"workers.worker2.readinessProbe.scheme":    "HTTP",
				"workers.worker2.readinessProbe.probeType": "httpGet",
			},
			ExpectedDeployments: []workerDeploymentTestCase{
				{
					ExpectedName:           "production-worker1",
					ExpectedCmd:            []string{"echo", "worker1"},
					ExpectedLivenessProbe:  defaultLivenessProbe(),
					ExpectedReadinessProbe: workerReadinessProbe(),
				},
				{
					ExpectedName:           "production-worker2",
					ExpectedCmd:            []string{"echo", "worker2"},
					ExpectedLivenessProbe:  defaultLivenessProbe(),
					ExpectedReadinessProbe: workerReadinessProbe(),
				},
			},
		},
	} {
		t.Run(tc.CaseName, func(t *testing.T) {
			namespaceName := "minimal-ruby-app-" + strings.ToLower(random.UniqueId())

			values := map[string]string{
				"gitlab.app": "auto-devops-examples/minimal-ruby-app",
				"gitlab.env": "prod",
			}

			mergeStringMap(values, tc.Values)

			options := &helm.Options{
				SetValues:      values,
				KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
			}

			output := helm.RenderTemplate(t, options, helmChartPath, tc.Release, []string{"templates/worker-deployment.yaml"})

			var deployments deploymentAppsV1List
			helm.UnmarshalK8SYaml(t, output, &deployments)

			require.Len(t, deployments.Items, len(tc.ExpectedDeployments))

			for i, expectedDeployment := range tc.ExpectedDeployments {
				deployment := deployments.Items[i]
				require.Equal(t, expectedDeployment.ExpectedName, deployment.Name)
				require.Len(t, deployment.Spec.Template.Spec.Containers, 1)
				require.Equal(t, expectedDeployment.ExpectedCmd, deployment.Spec.Template.Spec.Containers[0].Command)
				require.Equal(t, expectedDeployment.ExpectedLivenessProbe, deployment.Spec.Template.Spec.Containers[0].LivenessProbe)
				require.Equal(t, expectedDeployment.ExpectedReadinessProbe, deployment.Spec.Template.Spec.Containers[0].ReadinessProbe)
			}
		})
	}
}

func TestWorkerDatabaseUrlEnvironmentVariable(t *testing.T) {
	releaseName := "worker-application-database-url-test"

	tcs := []struct {
		CaseName            string
		Values              map[string]string
		ExpectedDatabaseUrl string
		Template            string
	}{
		{
			CaseName: "present-worker",
			Values: map[string]string{
				"application.database_url":   "PRESENT",
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
			},
			ExpectedDatabaseUrl: "PRESENT",
			Template:            "templates/worker-deployment.yaml",
		},
		{
			CaseName: "missing-db-migrate",
			Values: map[string]string{
				"workers.worker1.command[0]": "echo",
				"workers.worker1.command[1]": "worker1",
			},
			Template: "templates/worker-deployment.yaml",
		},
	}

	for _, tc := range tcs {
		t.Run(tc.CaseName, func(t *testing.T) {

			namespaceName := "minimal-ruby-app-" + strings.ToLower(random.UniqueId())

			values := map[string]string{
				"gitlab.app": "auto-devops-examples/minimal-ruby-app",
				"gitlab.env": "prod",
			}

			mergeStringMap(values, tc.Values)

			options := &helm.Options{
				SetValues:      values,
				KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
			}

			output, err := helm.RenderTemplateE(t, options, helmChartPath, releaseName, []string{tc.Template})

			if err != nil {
				t.Error(err)
				return
			}

			var deployments deploymentAppsV1List
			helm.UnmarshalK8SYaml(t, output, &deployments)

			if tc.ExpectedDatabaseUrl != "" {
				require.Contains(t, deployments.Items[0].Spec.Template.Spec.Containers[0].Env, coreV1.EnvVar{Name: "DATABASE_URL", Value: tc.ExpectedDatabaseUrl})
			} else {
				for _, envVar := range deployments.Items[0].Spec.Template.Spec.Containers[0].Env {
					require.NotEqual(t, "DATABASE_URL", envVar.Name)
				}
			}
		})
	}
}
