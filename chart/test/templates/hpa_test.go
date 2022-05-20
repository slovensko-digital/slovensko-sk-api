package main

import (
	"os"
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
	autoscalingV1 "k8s.io/api/autoscaling/v1"
	autoscalingV2Beta2 "k8s.io/api/autoscaling/v2beta2"
)

func TestHPA_AutoscalingV1(t *testing.T) {
	templates := []string{"templates/hpa.yaml"}
	releaseName := "hpa-test"

	tcs := []struct {
		name   string
		values map[string]string

		expectedName        string
		expectedMinReplicas int32
		expectedMaxReplicas int32
		expectedTargetCPU   int32

		expectedErrorRegexp *regexp.Regexp
	}{
		{
			name:                "defaults",
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/hpa.yaml in chart"),
		},
		{
			name:                "with hpa enabled, no requests",
			values:              map[string]string{"hpa.enabled": "true"},
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/hpa.yaml in chart"),
		},
		{
			name:                "with hpa enabled and requests defined",
			values:              map[string]string{"hpa.enabled": "true", "resources.requests.cpu": "500"},
			expectedName:        "hpa-test-auto-deploy",
			expectedMinReplicas: 1,
			expectedMaxReplicas: 5,
			expectedTargetCPU:   80,
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			output, ret := renderTemplate(t, tc.values, releaseName, templates, tc.expectedErrorRegexp)

			if ret == false {
				return
			}

			hpa := new(autoscalingV1.HorizontalPodAutoscaler)
			helm.UnmarshalK8SYaml(t, output, hpa)
			require.Equal(t, tc.expectedName, hpa.ObjectMeta.Name)
			require.Equal(t, tc.expectedMinReplicas, *hpa.Spec.MinReplicas)
			require.Equal(t, tc.expectedMaxReplicas, hpa.Spec.MaxReplicas)
			require.Equal(t, tc.expectedTargetCPU, *hpa.Spec.TargetCPUUtilizationPercentage)
		})
	}
}

func TestHPA_AutoscalingV2beta2(t *testing.T) {
	templates := []string{"templates/hpa.yaml"}
	releaseName := "hpa-test"

	tcs := []struct {
		name   string
		values string

		expectedName               string
		expectedMinReplicas        int32
		expectedMaxReplicas        int32
		expectedAverageUtilization int32

		expectedErrorRegexp *regexp.Regexp
	}{
		{
			name:                "defaults",
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/hpa.yaml in chart"),
		},
		{
			name: "with hpa enabled, and both metrics and requests defined",
			values: `
hpa:
  enabled: true
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
resources:
  requests:
    cpu: 500
`,
			expectedName:               "hpa-test-auto-deploy",
			expectedMinReplicas:        1,
			expectedMaxReplicas:        5,
			expectedAverageUtilization: 80,
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			f, err := os.CreateTemp("", "")
			defer os.Remove(f.Name())
			require.NoError(t, err)
			f.WriteString(tc.values)

			opts := &helm.Options{ValuesFiles: []string{f.Name()}}
			output, err := helm.RenderTemplateE(t, opts, helmChartPath, releaseName, templates)

			if tc.expectedErrorRegexp != nil {
				if err == nil {
					t.Error("Expected error but didn't happen")
				} else {
					require.Regexp(t, tc.expectedErrorRegexp, err.Error())
				}
				return
			}
			if err != nil {
				t.Error(err)
				return
			}

			hpa := new(autoscalingV2Beta2.HorizontalPodAutoscaler)
			helm.UnmarshalK8SYaml(t, output, hpa)
			require.Equal(t, tc.expectedName, hpa.ObjectMeta.Name)
			require.Equal(t, tc.expectedMinReplicas, *hpa.Spec.MinReplicas)
			require.Equal(t, tc.expectedMaxReplicas, hpa.Spec.MaxReplicas)
			require.Equal(t, tc.expectedAverageUtilization, *hpa.Spec.Metrics[0].Resource.Target.AverageUtilization)
		})
	}
}
