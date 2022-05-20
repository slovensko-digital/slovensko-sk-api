## Contributing

Thank you for your interest in contributing to this GitLab project! We welcome
all contributions. By participating in this project, you agree to abide by the
[code of conduct](#code-of-conduct).


## Developer Certificate of Origin + License

By contributing to GitLab B.V., You accept and agree to the following terms and
conditions for Your present and future Contributions submitted to GitLab B.V.
Except for the license granted herein to GitLab B.V. and recipients of software
distributed by GitLab B.V., You reserve all right, title, and interest in and to
Your Contributions. All Contributions are subject to the following DCO + License
terms.

[DCO + License](https://gitlab.com/gitlab-org/dco/blob/master/README.md)

_This notice should stay as the first item in the CONTRIBUTING.md file._

## Code of conduct

We want to create a welcoming environment for everyone who is interested
in contributing. Please visit our [Code of Conduct
page](https://about.gitlab.com/contributing/code-of-conduct) to learn
more about our commitment to an open and welcoming environment.

## Merge request guidelines

Below are some guidelines for merge requests:

- Any new configuration option should be documented in
  the `Configuration` section in README.md.
- For any template changes, we encourage a test case be added or
  updated in the
  [template tests](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/blob/master/test/template_test.go).

### Working with the tests

The tests are written in [Go](https://golang.org) (version 1.13 or later,
with [modules enabled](https://golang.org/cmd/go/#hdr-Module_support)) using
the [Terratest](https://github.com/gruntwork-io/terratest) library. To work
on the tests, you need to have [Helm 2](https://v2.helm.sh/docs/) and
[Go](https://golang.org) installed.

To run the tests, run the following commands from the root of your copy of `auto-deploy-app`:

```shell
helm repo add stable https://charts.helm.sh/stable # required only once
helm dependency build .               # required any time the dependencies change
cd test
GO111MODULE=auto go test ./...        # required for every change to the tests or the template
```

### Windows users

Some of the dependencies might not be available on Windows (e.g., `github.com/sirupsen/logrus/hooks/syslog`). Therefore we recommend running tests on docker, vagrant boxes or similar virtualization tools.