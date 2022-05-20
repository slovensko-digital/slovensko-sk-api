package main

import (
	"regexp"
	"testing"

	v2 "github.com/cilium/cilium/pkg/k8s/apis/cilium.io/v2"
	slim_metav1 "github.com/cilium/cilium/pkg/k8s/slim/k8s/apis/meta/v1"
	"github.com/cilium/cilium/pkg/policy/api"
	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func TestCiliumNetworkPolicy(t *testing.T) {
	releaseName := "cilium-network-policy-test"
	templates := []string{"templates/cilium-network-policy.yaml"}
	expectedLabels := map[string]string{
		"app":                          releaseName,
		"chart":                        chartName,
		"release":                      releaseName,
		"heritage":                     "Helm",
		"app.kubernetes.io/name":       releaseName,
		"helm.sh/chart":                chartName,
		"app.kubernetes.io/managed-by": "Helm",
		"app.kubernetes.io/instance":   releaseName,
		"app.gitlab.com/proj":          "",
	}
	expectedLabelsWithProjectID := map[string]string{
		"app":                          releaseName,
		"chart":                        chartName,
		"release":                      releaseName,
		"heritage":                     "Helm",
		"app.kubernetes.io/name":       releaseName,
		"helm.sh/chart":                chartName,
		"app.kubernetes.io/managed-by": "Helm",
		"app.kubernetes.io/instance":   releaseName,
		"app.gitlab.com/proj":          "91",
	}

	tcs := []struct {
		name       string
		valueFiles []string
		values     map[string]string

		expectedErrorRegexp *regexp.Regexp

		meta             metav1.ObjectMeta
		endpointSelector api.EndpointSelector
		ingress          []api.IngressRule
		egress           []api.EgressRule
	}{
		{
			name:                "disabled by default",
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/cilium-network-policy.yaml in chart"),
		},
		{
			name:   "with default policy without project ID",
			values: map[string]string{"ciliumNetworkPolicy.enabled": "true"},
			meta:   metav1.ObjectMeta{Name: releaseName + "-auto-deploy", Labels: expectedLabels},
			endpointSelector: api.EndpointSelector{
				LabelSelector: &slim_metav1.LabelSelector{MatchLabels: map[string]string(nil)},
			},
			ingress: []api.IngressRule{
				{
					FromEndpoints: []api.EndpointSelector{
						{LabelSelector: &slim_metav1.LabelSelector{
							MatchLabels: map[string]string{"any.app.gitlab.com/managed_by": "gitlab"},
						}},
					},
				},
			},
		},
		{
			name:   "with default policy",
			values: map[string]string{"ciliumNetworkPolicy.enabled": "true", "gitlab.projectID": "91"},
			meta:   metav1.ObjectMeta{Name: releaseName + "-auto-deploy", Labels: expectedLabelsWithProjectID},
			endpointSelector: api.EndpointSelector{
				LabelSelector: &slim_metav1.LabelSelector{MatchLabels: map[string]string(nil)},
			},
			ingress: []api.IngressRule{
				{
					FromEndpoints: []api.EndpointSelector{
						{LabelSelector: &slim_metav1.LabelSelector{
							MatchLabels: map[string]string{"any.app.gitlab.com/managed_by": "gitlab"},
						}},
					},
				},
			},
		},
		{
			name:       "with custom policy without alerts",
			valueFiles: []string{"../testdata/custom-cilium-policy.yaml"},
			values:     map[string]string{"ciliumNetworkPolicy.enabled": "true", "gitlab.projectID": "91", "ciliumNetworkPolicy.alerts.enabled": "false"},
			meta:       metav1.ObjectMeta{Name: releaseName + "-auto-deploy", Labels: expectedLabelsWithProjectID},
			endpointSelector: api.EndpointSelector{
				LabelSelector: &slim_metav1.LabelSelector{MatchLabels: map[string]string(nil)},
			},
			ingress: []api.IngressRule{
				{
					FromEndpoints: []api.EndpointSelector{
						{LabelSelector: &slim_metav1.LabelSelector{
							MatchLabels: map[string]string{"any.app.gitlab.com/managed_by": "gitlab"},
						}},
					},
				},
			},
		},
		{
			name:       "with custom policy with alerts",
			valueFiles: []string{"../testdata/custom-cilium-policy.yaml"},
			values:     map[string]string{"ciliumNetworkPolicy.enabled": "true", "gitlab.projectID": "91"},
			meta:       metav1.ObjectMeta{Name: releaseName + "-auto-deploy", Labels: expectedLabelsWithProjectID, Annotations: map[string]string{"app.gitlab.com/alert": "true"}},
			endpointSelector: api.EndpointSelector{
				LabelSelector: &slim_metav1.LabelSelector{MatchLabels: map[string]string(nil)},
			},
			ingress: []api.IngressRule{
				{
					FromEndpoints: []api.EndpointSelector{
						{LabelSelector: &slim_metav1.LabelSelector{
							MatchLabels: map[string]string{"any.app.gitlab.com/managed_by": "gitlab"},
						}},
					},
				},
			},
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			opts := &helm.Options{
				ValuesFiles: tc.valueFiles,
				SetValues:   tc.values,
			}
			output, err := helm.RenderTemplateE(t, opts, helmChartPath, releaseName, templates)

			if tc.expectedErrorRegexp != nil {
				require.Regexp(t, tc.expectedErrorRegexp, err.Error())
				return
			}
			if err != nil {
				t.Error(err)
				return
			}

			policy := new(v2.CiliumNetworkPolicy)
			helm.UnmarshalK8SYaml(t, output, policy)

			require.Equal(t, tc.meta, policy.ObjectMeta)
			require.Equal(t, tc.endpointSelector.LabelSelector, policy.Spec.EndpointSelector.LabelSelector)
			require.Equal(t, tc.ingress[0].FromEndpoints[0].LabelSelector, policy.Spec.Ingress[0].FromEndpoints[0].LabelSelector)
			require.Equal(t, len(tc.ingress), len(policy.Spec.Ingress))
			require.Equal(t, len(tc.ingress[0].FromEndpoints), len(policy.Spec.Ingress[0].FromEndpoints))
		})
	}
}
