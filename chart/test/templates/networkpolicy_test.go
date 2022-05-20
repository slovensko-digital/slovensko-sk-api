package main

import (
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
	netV1 "k8s.io/api/networking/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func TestNetworkPolicy(t *testing.T) {
	releaseName := "network-policy-test"
	templates := []string{"templates/network-policy.yaml"}
	expectedLabels := map[string]string{
		"app":                          releaseName,
		"chart":                        chartName,
		"release":                      releaseName,
		"heritage":                     "Helm",
		"app.kubernetes.io/name":       releaseName,
		"helm.sh/chart":                chartName,
		"app.kubernetes.io/managed-by": "Helm",
		"app.kubernetes.io/instance":   releaseName,
	}

	tcs := []struct {
		name       string
		valueFiles []string
		values     map[string]string

		expectedErrorRegexp *regexp.Regexp

		meta        metav1.ObjectMeta
		podSelector metav1.LabelSelector
		policyTypes []netV1.PolicyType
		ingress     []netV1.NetworkPolicyIngressRule
		egress      []netV1.NetworkPolicyEgressRule
	}{
		{
			name:                "disabled by default",
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/network-policy.yaml in chart"),
		},
		{
			name:        "with default policy",
			values:      map[string]string{"networkPolicy.enabled": "true"},
			meta:        metav1.ObjectMeta{Name: releaseName + "-auto-deploy", Labels: expectedLabels},
			podSelector: metav1.LabelSelector{MatchLabels: map[string]string{}},
			ingress: []netV1.NetworkPolicyIngressRule{
				{
					From: []netV1.NetworkPolicyPeer{
						{PodSelector: &metav1.LabelSelector{MatchLabels: map[string]string{}}},
						{NamespaceSelector: &metav1.LabelSelector{
							MatchLabels: map[string]string{"app.gitlab.com/managed_by": "gitlab"},
						}},
					},
				},
			},
		},
		{
			name:        "with custom policy",
			valueFiles:  []string{"../testdata/custom-policy.yaml"},
			meta:        metav1.ObjectMeta{Name: releaseName + "-auto-deploy", Labels: expectedLabels},
			podSelector: metav1.LabelSelector{MatchLabels: map[string]string{"foo": "bar"}},
			ingress: []netV1.NetworkPolicyIngressRule{
				{
					From: []netV1.NetworkPolicyPeer{
						{PodSelector: &metav1.LabelSelector{MatchLabels: map[string]string{}}},
						{NamespaceSelector: &metav1.LabelSelector{
							MatchLabels: map[string]string{"name": "foo"},
						}},
					},
				},
			},
		},
		{
			name:        "with full spec policy",
			valueFiles:  []string{"../testdata/full-spec-policy.yaml"},
			meta:        metav1.ObjectMeta{Name: releaseName + "-auto-deploy", Labels: expectedLabels},
			podSelector: metav1.LabelSelector{MatchLabels: map[string]string{}},
			policyTypes: []netV1.PolicyType{"Ingress", "Egress"},
			ingress: []netV1.NetworkPolicyIngressRule{
				{
					From: []netV1.NetworkPolicyPeer{
						{PodSelector: &metav1.LabelSelector{MatchLabels: map[string]string{}}},
					},
				},
			},
			egress: []netV1.NetworkPolicyEgressRule{
				{
					To: []netV1.NetworkPolicyPeer{
						{NamespaceSelector: &metav1.LabelSelector{
							MatchLabels: map[string]string{"name": "gitlab-managed-apps"},
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

			policy := new(netV1.NetworkPolicy)
			helm.UnmarshalK8SYaml(t, output, policy)

			require.Equal(t, tc.meta, policy.ObjectMeta)
			require.Equal(t, tc.podSelector, policy.Spec.PodSelector)
			require.Equal(t, tc.policyTypes, policy.Spec.PolicyTypes)
			require.Equal(t, tc.ingress, policy.Spec.Ingress)
			require.Equal(t, tc.egress, policy.Spec.Egress)
		})
	}
}
