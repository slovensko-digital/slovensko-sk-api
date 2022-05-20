package main

import (
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
	coreV1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func TestPvcTemplate_Single(t *testing.T) {
	templates := []string{"templates/pvc.yaml"}
	releaseName := "test"
	customStorageClassName := "MyStorageClass"
	expectedLabels := map[string]string{
		"app":                          releaseName,
		"chart":                        chartName,
		"release":                      releaseName,
		"heritage":                     "Helm",
		"app.kubernetes.io/name":       releaseName,
		"helm.sh/chart":                chartName,
		"app.kubernetes.io/managed-by": "Helm",
		"app.kubernetes.io/instance":   releaseName,
		"tier":                         "web",
		"track":                        "stable",
	}
	tcs := []struct {
		name   string
		values map[string]string

		expectedMeta        metav1.ObjectMeta
		expectedPVC         coreV1.PersistentVolumeClaimSpec
		expectedErrorRegexp *regexp.Regexp
	}{
		{
			name:         "defaults",
			values:       map[string]string{"persistence.enabled": "true"},
			expectedMeta: metav1.ObjectMeta{Name: "test-auto-deploy-data", Labels: expectedLabels},
			expectedPVC: coreV1.PersistentVolumeClaimSpec{
				AccessModes: [](coreV1.PersistentVolumeAccessMode){coreV1.ReadWriteOnce},
				Resources:   coreV1.ResourceRequirements{Requests: coreV1.ResourceList{"storage": resource.MustParse("8Gi")}},
			},
		},
		{
			name: "with different parameters",
			values: map[string]string{
				"persistence.enabled":                       "true",
				"persistence.volumes[0].name":               "log-dir",
				"persistence.volumes[0].claim.accessMode":   "ReadOnlyMany",
				"persistence.volumes[0].claim.size":         "20Gi",
				"persistence.volumes[0].claim.storageClass": customStorageClassName,
				"persistence.volumes[0].mount.path":         "/log",
			},
			expectedMeta: metav1.ObjectMeta{Name: "test-auto-deploy-log-dir", Labels: expectedLabels},
			expectedPVC: coreV1.PersistentVolumeClaimSpec{
				AccessModes:      [](coreV1.PersistentVolumeAccessMode){coreV1.ReadOnlyMany},
				Resources:        coreV1.ResourceRequirements{Requests: coreV1.ResourceList{"storage": resource.MustParse("20Gi")}},
				StorageClassName: &customStorageClassName,
			},
		},
		{
			name:                "when disabled",
			values:              map[string]string{"persistence.enabled": "false"},
			expectedErrorRegexp: regexp.MustCompile("error while running command: exit status 1; Error: could not find template templates/pvc.yaml in chart"),
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			output, ret := renderTemplate(t, tc.values, releaseName, templates, tc.expectedErrorRegexp)

			if ret == false {
				return
			}

			pvc := new(coreV1.PersistentVolumeClaim)
			helm.UnmarshalK8SYaml(t, output, pvc)

			require.Equal(t, tc.expectedMeta, pvc.ObjectMeta)
			require.Equal(t, tc.expectedPVC.AccessModes, pvc.Spec.AccessModes)
			require.Equal(t, tc.expectedPVC.Resources.Requests["storage"], pvc.Spec.Resources.Requests["storage"])
			require.Equal(t, tc.expectedPVC.StorageClassName, pvc.Spec.StorageClassName)
		})
	}
}

func TestPvcTemplate_Multiple(t *testing.T) {
	templates := []string{"templates/pvc.yaml"}
	releaseName := "test"
	customStorageClassName := "MyStorageClass"
	expectedLabels := map[string]string{
		"app":                          releaseName,
		"chart":                        chartName,
		"release":                      releaseName,
		"heritage":                     "Helm",
		"app.kubernetes.io/name":       releaseName,
		"helm.sh/chart":                chartName,
		"app.kubernetes.io/managed-by": "Helm",
		"app.kubernetes.io/instance":   releaseName,
		"tier":                         "web",
		"track":                        "stable",
	}
	tcs := []struct {
		name   string
		values map[string]string

		expectedMetas       []metav1.ObjectMeta
		expectedPVCs        []coreV1.PersistentVolumeClaimSpec
		expectedErrorRegexp *regexp.Regexp
	}{
		{
			name: "with multiple PVCs",
			values: map[string]string{
				"persistence.enabled":                       "true",
				"persistence.volumes[0].name":               "data",
				"persistence.volumes[0].claim.accessMode":   "ReadWriteOnce",
				"persistence.volumes[0].claim.size":         "8Gi",
				"persistence.volumes[0].mount.path":         "/data",
				"persistence.volumes[1].name":               "log_dir",
				"persistence.volumes[1].claim.accessMode":   "ReadOnlyMany",
				"persistence.volumes[1].claim.size":         "20Gi",
				"persistence.volumes[1].claim.storageClass": customStorageClassName,
				"persistence.volumes[1].mount.path":         "/log",
			},
			expectedMetas: []metav1.ObjectMeta{
				{Name: "data", Labels: expectedLabels},
				{Name: "log-dir", Labels: expectedLabels},
			},
			expectedPVCs: []coreV1.PersistentVolumeClaimSpec{
				{
					AccessModes: [](coreV1.PersistentVolumeAccessMode){coreV1.ReadWriteOnce},
					Resources:   coreV1.ResourceRequirements{Requests: coreV1.ResourceList{"storage": resource.MustParse("8Gi")}},
				},
				{
					AccessModes:      [](coreV1.PersistentVolumeAccessMode){coreV1.ReadOnlyMany},
					Resources:        coreV1.ResourceRequirements{Requests: coreV1.ResourceList{"storage": resource.MustParse("20Gi")}},
					StorageClassName: &customStorageClassName,
				},
			},
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			output, ret := renderTemplate(t, tc.values, releaseName, templates, tc.expectedErrorRegexp)

			if ret == false {
				return
			}

			pvcList := strings.Split(output, "---")
			for i, pvcOutput := range pvcList[1:] {
				pvc := new(coreV1.PersistentVolumeClaim)
				helm.UnmarshalK8SYaml(t, pvcOutput, pvc)

				require.Equal(t, tc.expectedPVCs[i].AccessModes, pvc.Spec.AccessModes)
				require.Equal(t, tc.expectedPVCs[i].Resources.Requests["storage"], pvc.Spec.Resources.Requests["storage"])
				require.Equal(t, tc.expectedPVCs[i].StorageClassName, pvc.Spec.StorageClassName)
			}
		})
	}
}
