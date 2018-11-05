docker-compose build

helm init --client-only --skip-refresh
helm package HelmCharts\ngcli-netcore --version 1.0.0
