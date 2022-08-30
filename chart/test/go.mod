module gitlab.com/gitlab-org/charts/auto-deploy-app/test

go 1.15

require (
	github.com/cilium/cilium v1.10.14
	github.com/gruntwork-io/terratest v0.32.1
	github.com/stretchr/testify v1.7.0
	gopkg.in/yaml.v3 v3.0.0-20200615113413-eeeca48fe776
	k8s.io/api v0.21.14
	k8s.io/apimachinery v0.21.14
)

replace github.com/optiopay/kafka => github.com/cilium/kafka v0.0.0-20180809090225-01ce283b732b
