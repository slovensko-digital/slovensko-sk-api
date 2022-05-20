package main

import (
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
	extensions "k8s.io/api/extensions/v1beta1"
	networkingv1 "k8s.io/api/networking/v1"
	networkingv1beta "k8s.io/api/networking/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func TestIngressTemplate_ModSecurity(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	modSecuritySnippet := "SecRuleEngine DetectionOnly\n"
	modSecuritySnippetWithSecRules := modSecuritySnippet + `SecRule REQUEST_HEADERS:User-Agent \"scanner\" \"log,deny,id:107,status:403,msg:\'Scanner Identified\'\"
SecRule REQUEST_HEADERS:Content-Type \"text/plain\" \"log,deny,id:\'20010\',status:403,msg:\'Text plain not allowed\'\"
`
	defaultAnnotations := map[string]string{
		"kubernetes.io/ingress.class": "nginx",
		"kubernetes.io/tls-acme":      "true",
	}
	defaultModSecurityAnnotations := map[string]string{
		"nginx.ingress.kubernetes.io/modsecurity-transaction-id": "$server_name-$request_id",
	}
	modSecurityAnnotations := make(map[string]string)
	secRulesAnnotations := make(map[string]string)
	mergeStringMap(modSecurityAnnotations, defaultAnnotations)
	mergeStringMap(modSecurityAnnotations, defaultModSecurityAnnotations)
	mergeStringMap(secRulesAnnotations, defaultAnnotations)
	mergeStringMap(secRulesAnnotations, defaultModSecurityAnnotations)
	modSecurityAnnotations["nginx.ingress.kubernetes.io/modsecurity-snippet"] = modSecuritySnippet
	secRulesAnnotations["nginx.ingress.kubernetes.io/modsecurity-snippet"] = modSecuritySnippetWithSecRules

	tcs := []struct {
		name       string
		valueFiles []string
		values     map[string]string
		meta       metav1.ObjectMeta
	}{
		{
			name: "defaults",
			meta: metav1.ObjectMeta{Annotations: defaultAnnotations},
		},
		{
			name:   "with modSecurity enabled without custom secRules",
			values: map[string]string{"ingress.modSecurity.enabled": "true"},
			meta:   metav1.ObjectMeta{Annotations: modSecurityAnnotations},
		},
		{
			name:       "with custom secRules",
			valueFiles: []string{"../testdata/modsecurity-ingress.yaml"},
			meta:       metav1.ObjectMeta{Annotations: secRulesAnnotations},
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			opts := &helm.Options{
				ValuesFiles: tc.valueFiles,
				SetValues:   tc.values,
			}
			output := helm.RenderTemplate(t, opts, helmChartPath, "ModSecurity-test-release", templates)

			ingress := new(extensions.Ingress)
			helm.UnmarshalK8SYaml(t, output, ingress)

			require.Equal(t, tc.meta.Annotations, ingress.ObjectMeta.Annotations)
		})
	}
}

func TestIngressTemplate_DifferentTracks(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	tcs := []struct {
		name        string
		releaseName string
		values      map[string]string

		expectedName                     string
		expectedLabels                   map[string]string
		expectedSelector                 map[string]string
		expectedAnnotations              map[string]string
		expectedInexistentAnnotationKeys []string
		expectedErrorRegexp              *regexp.Regexp
	}{
		{
			name:                             "defaults",
			releaseName:                      "production",
			expectedName:                     "production-auto-deploy",
			expectedAnnotations:              map[string]string{"kubernetes.io/ingress.class": "nginx"},
			expectedInexistentAnnotationKeys: []string{"nginx.ingress.kubernetes.io/canary"},
		},
		{
			name:                             "with canary track",
			releaseName:                      "production-canary",
			values:                           map[string]string{"application.track": "canary"},
			expectedName:                     "production-canary-auto-deploy",
			expectedAnnotations:              map[string]string{"nginx.ingress.kubernetes.io/canary": "true", "nginx.ingress.kubernetes.io/canary-by-header": "canary", "kubernetes.io/ingress.class": "nginx"},
			expectedInexistentAnnotationKeys: []string{"nginx.ingress.kubernetes.io/canary-weight"},
		},
		{
			name:                "with canary weight",
			releaseName:         "production-canary",
			values:              map[string]string{"application.track": "canary", "ingress.canary.weight": "25"},
			expectedName:        "production-canary-auto-deploy",
			expectedAnnotations: map[string]string{"nginx.ingress.kubernetes.io/canary-weight": "25"},
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			output, ret := renderTemplate(t, tc.values, tc.releaseName, templates, tc.expectedErrorRegexp)

			if ret == false {
				return
			}

			ingress := new(extensions.Ingress)
			helm.UnmarshalK8SYaml(t, output, ingress)
			require.Equal(t, tc.expectedName, ingress.ObjectMeta.Name)
			for key, value := range tc.expectedAnnotations {
				require.Equal(t, ingress.ObjectMeta.Annotations[key], value)
			}
			for _, key := range tc.expectedInexistentAnnotationKeys {
				require.Empty(t, ingress.ObjectMeta.Annotations[key])
			}
		})
	}
}

func TestIngressTemplate_TLS(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	releaseName := "ingress-tls-test"
	tcs := []struct {
		name   string
		values map[string]string

		expectedAnnotations map[string]string
		expectedIngressTLS  []extensions.IngressTLS
		expectedErrorRegexp *regexp.Regexp
	}{
		{
			name:                "defaults",
			expectedAnnotations: map[string]string{"kubernetes.io/ingress.class": "nginx", "kubernetes.io/tls-acme": "true"},
			expectedIngressTLS: []extensions.IngressTLS{
				extensions.IngressTLS{
					Hosts:      []string{"my.host.com"},
					SecretName: releaseName + "-auto-deploy-tls",
				},
			},
		},
		{
			name:                "with tls disabled",
			values:              map[string]string{"ingress.tls.enabled": "false"},
			expectedAnnotations: map[string]string{"kubernetes.io/ingress.class": "nginx"},
			expectedIngressTLS:  []extensions.IngressTLS(nil),
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			output, ret := renderTemplate(t, tc.values, releaseName, templates, tc.expectedErrorRegexp)

			if ret == false {
				return
			}

			ingress := new(extensions.Ingress)
			helm.UnmarshalK8SYaml(t, output, ingress)
			require.Equal(t, tc.expectedAnnotations, ingress.ObjectMeta.Annotations)
			require.Equal(t, tc.expectedIngressTLS, ingress.Spec.TLS)
		})
	}
}

func TestIngressTemplate_Disable(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	releaseName := "ingress-disable-test"
	tcs := []struct {
		name   string
		values map[string]string

		expectedName        string
		expectedErrorRegexp *regexp.Regexp
	}{
		{
			name:         "defaults",
			expectedName: releaseName + "-auto-deploy",
		},
		{
			name:         "with ingress.enabled key undefined, but service is enabled",
			values:       map[string]string{"ingress.enabled": "null", "service.enabled": "true"},
			expectedName: releaseName + "-auto-deploy",
		},
		{
			name:                "with service disabled and track stable",
			values:              map[string]string{"service.enabled": "false", "application.track": "stable"},
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/ingress.yaml in chart"),
		},
		{
			name:                "with service disabled and track non-stable",
			values:              map[string]string{"service.enabled": "false", "application.track": "non-stable"},
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/ingress.yaml in chart"),
		},
		{
			name:                "with ingress disabled",
			values:              map[string]string{"ingress.enabled": "false"},
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/ingress.yaml in chart"),
		},
		{
			name:                "with ingress enabled and service disabled",
			values:              map[string]string{"ingress.enabled": "true", "service.enabled": "false"},
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/ingress.yaml in chart"),
		},
		{
			name:                "with ingress disabled and service enabled and track stable",
			values:              map[string]string{"ingress.enabled": "false", "service.enabled": "true", "application.track": "stable"},
			expectedErrorRegexp: regexp.MustCompile("Error: could not find template templates/ingress.yaml in chart"),
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			opts := &helm.Options{
				SetValues: tc.values,
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

			ingress := new(extensions.Ingress)
			helm.UnmarshalK8SYaml(t, output, ingress)
			require.Equal(t, tc.expectedName, ingress.ObjectMeta.Name)
		})
	}
}

func TestIngressTemplate_HTTPPath(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	releaseName := "ingress-http-path-test"
	tcs := []struct {
		name   string
		values map[string]string

		expectedpath string
	}{
		{
			name:         "defaults",
			expectedpath: "/",
		},
		{
			name:         "with /*",
			values:       map[string]string{"ingress.path": "/*"},
			expectedpath: "/*",
		},
		{
			name:         "with /myapi",
			values:       map[string]string{"ingress.path": "/myapi"},
			expectedpath: "/myapi",
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			opts := &helm.Options{
				SetValues: tc.values,
			}
			output := helm.RenderTemplate(t, opts, helmChartPath, releaseName, templates)

			ingress := new(extensions.Ingress)

			helm.UnmarshalK8SYaml(t, output, ingress)
			require.Equal(t, tc.expectedpath, ingress.Spec.Rules[0].IngressRuleValue.HTTP.Paths[0].Path)
		})
	}
}

func TestIngressTemplate_TLSSecret(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	releaseName := "ingress-secret-name-test"
	tcs := []struct {
		name   string
		values map[string]string

		expectedsecretname string
	}{
		{
			name:               "default condition from values - use the provided secretName",
			expectedsecretname: releaseName + "-auto-deploy-tls",
		},
		{
			name:               "don't set the secretName, use the default secret/cert",
			values:             map[string]string{"ingress.tls.useDefaultSecret": "true"},
			expectedsecretname: "",
		},
		{
			name:               "use the provided secretName",
			values:             map[string]string{"ingress.useDefaultSecret": "false"},
			expectedsecretname: releaseName + "-auto-deploy-tls",
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			opts := &helm.Options{
				SetValues: tc.values,
			}
			output := helm.RenderTemplate(t, opts, helmChartPath, releaseName, templates)

			ingress := new(extensions.Ingress)

			helm.UnmarshalK8SYaml(t, output, ingress)
			require.Equal(t, tc.expectedsecretname, ingress.Spec.TLS[0].SecretName)
		})
	}
}

func TestIngressTemplate_NetworkingV1Beta1(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	releaseName := "ingress-networking-v1beta1"
	opts := &helm.Options{
		SetValues: map[string]string{"ingress.enabled": "true"},
	}
	output := helm.RenderTemplate(t, opts, helmChartPath, releaseName, templates, "--api-versions", "networking.k8s.io/v1beta1/Ingress")
	ingress := new(networkingv1beta.Ingress)
	helm.UnmarshalK8SYaml(t, output, ingress)
	require.Equal(t, "networking.k8s.io/v1beta1", ingress.APIVersion)
}

func TestIngressTemplate_NetworkingV1(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	releaseName := "ingress-networking-v1"
	opts := &helm.Options{
		SetValues: map[string]string{"ingress.enabled": "true"},
	}
	output := helm.RenderTemplate(t, opts, helmChartPath, releaseName, templates, "--api-versions", "networking.k8s.io/v1/Ingress")
	ingress := new(networkingv1.Ingress)
	helm.UnmarshalK8SYaml(t, output, ingress)
	require.Equal(t, "networking.k8s.io/v1", ingress.APIVersion)
	require.Equal(t, "nginx", *ingress.Spec.IngressClassName)
	require.NotContains(t, "kubernetes.io/ingress.class", ingress.Annotations)
}

func TestIngressTemplate_Extensions(t *testing.T) {
	templates := []string{"templates/ingress.yaml"}
	releaseName := "ingress-extensions-v1beta1"
	opts := &helm.Options{
		SetValues: map[string]string{"ingress.enabled": "true"},
	}
	output := helm.RenderTemplate(t, opts, helmChartPath, releaseName, templates, "--api-versions", "extensions/v1beta1/Ingress")
	ingress := new(extensions.Ingress)
	helm.UnmarshalK8SYaml(t, output, ingress)
	require.Equal(t, "extensions/v1beta1", ingress.APIVersion)
	require.Equal(t, "nginx", ingress.Annotations["kubernetes.io/ingress.class"])
}
