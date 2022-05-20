package main

import (
	"io"
	"log"
	"os"
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	appsV1 "k8s.io/api/apps/v1"
	coreV1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

const (
	helmChartPath = "../.."
)

var chartName string // dynamically initialized

func init() {
	// init chartName dynamically because it is annoying to update this value, but it is needed for some expected labels
	f, err := os.Open(helmChartPath + "/Chart.yaml")
	if err != nil {
		log.Fatalf("Failed to open Chart.yaml: %v", err)
	}
	b, err := io.ReadAll(f)
	if err != nil {
		log.Fatalf("Failed to read Chart.yaml: %v", err)
	}
	m := make(map[interface{}]interface{})
	err = yaml.Unmarshal(b, m)
	if err != nil {
		log.Fatalf("Failed to unmarshal Chart.yaml: %v", err)
	}
	chartName = "auto-deploy-app-" + m["version"].(string)
}

func renderTemplate(t *testing.T, values map[string]string, releaseName string, templates []string, expectedErrorRegexp *regexp.Regexp) (string, bool) {
	opts := &helm.Options{
		SetValues: values,
	}

	output, err := helm.RenderTemplateE(t, opts, helmChartPath, releaseName, templates)
	if expectedErrorRegexp != nil {
		if err == nil {
			t.Error("Expected error but didn't happen")
		} else {
			require.Regexp(t, expectedErrorRegexp, err.Error())
		}
		return "", false
	}
	if err != nil {
		t.Error(err)
		return "", false
	}

	return output, true
}

type workerDeploymentTestCase struct {
	ExpectedName           string
	ExpectedCmd            []string
	ExpectedStrategyType   appsV1.DeploymentStrategyType
	ExpectedSelector       *metav1.LabelSelector
	ExpectedLifecycle      *coreV1.Lifecycle
	ExpectedLivenessProbe  *coreV1.Probe
	ExpectedReadinessProbe *coreV1.Probe
	ExpectedNodeSelector   map[string]string
	ExpectedTolerations    []coreV1.Toleration
	ExpectedInitContainers []coreV1.Container
	ExpectedAffinity       *coreV1.Affinity
}

type workerDeploymentSelectorTestCase struct {
	ExpectedName     string
	ExpectedSelector *metav1.LabelSelector
}

type workerDeploymentServiceAccountTestCase struct {
	ExpectedServiceAccountName string
}

type deploymentList struct {
	metav1.TypeMeta `json:",inline"`

	Items []appsV1.Deployment `json:"items" protobuf:"bytes,2,rep,name=items"`
}

type deploymentAppsV1List struct {
	metav1.TypeMeta `json:",inline"`

	Items []appsV1.Deployment `json:"items" protobuf:"bytes,2,rep,name=items"`
}

func mergeStringMap(dst, src map[string]string) {
	for k, v := range src {
		dst[k] = v
	}
}

func defaultLivenessProbe() *coreV1.Probe {
	return &coreV1.Probe{
		Handler: coreV1.Handler{
			HTTPGet: &coreV1.HTTPGetAction{
				Path:   "/",
				Port:   intstr.FromInt(5000),
				Scheme: coreV1.URISchemeHTTP,
			},
		},
		InitialDelaySeconds: 15,
		TimeoutSeconds:      15,
	}
}

func defaultReadinessProbe() *coreV1.Probe {
	return &coreV1.Probe{
		Handler: coreV1.Handler{
			HTTPGet: &coreV1.HTTPGetAction{
				Path:   "/",
				Port:   intstr.FromInt(5000),
				Scheme: coreV1.URISchemeHTTP,
			},
		},
		InitialDelaySeconds: 5,
		TimeoutSeconds:      3,
	}
}

func workerLivenessProbe() *coreV1.Probe {
	return &coreV1.Probe{
		Handler: coreV1.Handler{
			HTTPGet: &coreV1.HTTPGetAction{
				Path:   "/worker",
				Port:   intstr.FromInt(5000),
				Scheme: coreV1.URISchemeHTTP,
			},
		},
		InitialDelaySeconds: 0,
		TimeoutSeconds:      0,
	}
}

func workerReadinessProbe() *coreV1.Probe {
	return &coreV1.Probe{
		Handler: coreV1.Handler{
			HTTPGet: &coreV1.HTTPGetAction{
				Path:   "/worker",
				Port:   intstr.FromInt(5000),
				Scheme: coreV1.URISchemeHTTP,
			},
		},
		InitialDelaySeconds: 0,
		TimeoutSeconds:      0,
	}
}
