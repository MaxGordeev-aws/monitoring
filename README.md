# Monitoring On Kubernetes Cluster

![alt text](https://storage.googleapis.com/grand-drive-196322.appspot.com/blog_pics/prom-k8s/prom-k8s-arch.png)

* Work was done by using Prometheus, Grafana, and for alerting Prometheus alert manager, sending alerts to slack.* 

**Prometheus is**

- A pull based system
- By default Prometheus comes with his own web UI. Prometheus uses PromQL language to query in this dashboard.
- Prometheus use exporters/agents, in my case I have used Kube state metric and Node Exporter, to convert existing metric to Prometheus metric format.
1. **Kube-state metrics** **used to get all the details about all the API objects like deployments, pods, daemonsets etc.** (get metrics like how many cpu use pods, how many pods are running). Basically it provides kubernetes API object metrics which you cannot get directly from native Kubernetes monitoring components. (
2. **Node Exporters**  **to get all the Kubernetes node-level system metrics.** By default, most of the Kubernetes clusters expose Cluster level metrics from the summary API, It does not provide detailed node-level metrics.

⇒ **Kube-state metrics and Node Exporters both of them have service yaml file that helps to expose all metrics in /metric endpoint.
/metrics - it’s a standard location of the metrics in Prometheus. All the components in K8s cluster will write their metrics into this folder, and Prometheus agents will go there and collect all the data.
If you need to scrape the data from a custom target e.g. application or database or anything like - like how many people downloaded video, clicked the button, watch the advertisement. We need to tell the Developer to write the script which will store all the metrics data in this folder. After that, we add another “scrape job” in the configuration file so the Prometheus will go there and get all the metrics. 

**Custom metrics for Prometheus**

Prometheus integrated with K8s, ingests data, and allows it to collect and process 4 types of metrics: counters, gauges, histograms, and summaries.
1.	Counters - cumulative metrics that can only increase or reset to 0. Good for measuring tasks completed, error, number of requests.
2.	Gauges - a point-in-time metric that can increase or decrease. Good for measuring concurrent requests or current memory usage.
3.	Histogram - get data and categorize it in custom groups. Good for aggregated measures request duration and response size.
4.	Summaries - get data and return total counts of observation, the sum of values. 

⇒ **Kube-state metrics and Node Exporters are by default too many metrics and we can modify to collect metrics specifically  that we want. (for example: if we have 1000 nodes and we collect more than 1000 of metrics - that is a lot.)**

- Prometheus stores by default all data locally, and uses Time-Series Database. In my case i have used PVC for Prometheus to store all data.

**Grafana is:**

- is a data visualization and analytics tool that allows to build dashboards and graphs for metrics data.
- When Grafana is used with Prometheus, it caused PromQL to query metrics from Prometheus.
- after installation Grafana, Grafana needs dashboards - so I imported dashboards to see Kubernetes cluster, Nodes, Pods and Ingress.


**Alert Manager is:**

- Is open-source alerting tool that works with prometheus.
- There are many integrations available to receive alerts from the Alertmanager (Slack, email, API endpoints etc)

During the interview might be question like when - where do you receive your alert notifications —> Pagerduty, Email/text notifications through SNS.

To set up config files I used:

1. YAML FILES 

2. And used Makefile to target all yaml files and by running one command to apply all Yaml files.

3. In Makefile the very first target is to create a **monitoring namespace**. So that monitoring tools will be deployed in monitoring namespace, not in default. (Note: but Prometheus collects all metrics from all namespaces)

⇒ **Instructions to set up Prometheus and Prometheus Components:**

1. **For Prometheus:**
    - **prometheus-clusterRole.yaml** - in the role we have added GET, LIST and WATCH permissions to nodes, services endpoints, pods and ingresses. And Role binding to bound to the namespace that we created.
    - **prometheus-configMap.yaml** - in cm we attached 2 data:

        → prometheus.yaml: This is the main Prometheus configuration which holds all the scrape configs, service discovery details, storage locations, data retention configs, etc

        → prometheus.rules: This file contains all the Prometheus alerting rules

        → The config map with all the Prometheus scrape config and alerting rules gets mounted to the Prometheus container in /etc/prometheus

    - **prometheus-deployment.yaml** -

        → This deployment uses the latest official Prometheus image from the docker hub.

        → In this configuration, we are mounting the Prometheus config map as a file inside /etc/prometheus. 

        → Also, we are using persistent volume for Prometheus storage

2. **For Kube State Metric:**
- **clusterRole.yaml** - there is a creation of service account named kube state metrics. Cluster Role- for kube state metrics to access all the Kubernetes API objects. Cluster Role Binding – Binds the service account with the cluster role.
- **deployment.yaml** - Kube State Metrics Deployment
- **service.yaml** - To expose the metrics

3.  **For Node Exporter:**

- **deamonset.yaml** - Deploy node exporter on all the Kubernetes nodes as a daemonset.
- **service.yaml** - Create a service that listens on port 9100 and points to all the daemonset node exporter pods.

⇒ **Instructions to set up Grafana:**

Here is all needed YAML files to deploy Grafana:

- **grafana-clusterRole.yaml** - there is a creation of service account named grafana. Cluster Role - to give permission to use podsecuritypolicy. Cluster Role Binding – Binds the service account with the cluster role.
- **grafana-datasource-config.yaml** - The following data source configuration is for Prometheus. If you have more data sources, you can add more data sources with different YAMLs under the data section. (**AWS cloud watch, Stackdriver**).
- **grafana-deployment.yaml** - to persist all the configs and data that Grafana uses, we mounted persistent volume.

    We mounted Secrets as an environment variable to our deployment- secrets are used to store username and password by which we can easily log into the Grafana.

    → Secrets are stored in AWS Secret Manager (by using [aws-secretsmanager-create-secrets.sh](http://aws-secretsmanager-create-secrets.sh) script)

    → In Deployment we used injected version of Secrets (were injected with [aws-secretsmanager-inject-secrets.sh](http://aws-secretsmanager-create-secrets.sh) script)

    → And if we would like to update - we can use [aws-secretsmanager-update-secrets.sh](http://aws-secretsmanager-create-secrets.sh) script.

- **grafana-pvc.yaml** - our persistent volume claim file


⇒ **Instructions to set up Alert Manager:**

- **AlertManagerConfigMap.yaml** - used to specify to what receiver should send notifications

in my case I used slack.

- Here I want to Note that we have to create webhook API for slack.

(on the bottom there is a link to an article of creation Slack webhook Api.

- **AlertTemplateConfigMap.yaml**  - this file is contains config to alert manager's content -  what i mean is in this file we can specify which kind of notifications should we get. And if we would like to change descriptions of notifications we can modify this file.
- Deployment.yaml - Alert manager is deployed with deployment
- In my case all my config files for Alert Manager are located in one folder with Prometheus,

    that is why in Makefile of Prometheus I have target for Alert Manager

(Marsel added in demo: 

- need to know differences between pull based and push based system
- Custom metrics in Prometheus and Grafana -

To configure custom metrics developers need to add in applications, and a pods need to expose this metrics in  a /metric endpoint, and we need to configure Prometheus - so it will need collect those custom metrics from pods and need to add dashboard to Grafana so it will show this custom metrics.

Kube state metric and Node Exporter show standard metrics. In real environment developers want to see custom metrics - like how many people downloaded video, click the button, watch the advertisement.)

# Issues

1. When I mounted Persistent Volume for Prometheus and Grafana I got an error "CrashLoopBackOff", logs were saying: "error: permission denied".

- Solution: added Init Container to change the user/permission of the Persistent Volume Claim.

Resource to solve this issue: 

https://github.com/prometheus/prometheus/issues/5976#issuecomment-595070057

https://faun.pub/digitalocean-kubernetes-and-volume-permissions-820f46598965

2. If there is no Service Account for Prometheus specifically. Service Account name for Prometheus must be *Default*.  

- The reason is when I changed name of Service Account for Prometheus to other name, I could not get cluster metrics. 

Resource to solve this issue: 

https://github.com/oracle/docker-images/issues/770#issuecomment-368147286

3. In Makefile make sure to specify location of the files and name of the files correctly.

- My issue was in Makefile all my configuration files had "yml" extensions, however my original configuration files had "yaml".

4. Make sure to use right namespaces in all manifest files. 

- My issue was: when I started to work on ticket, tutorial that I found had another namespace for Kube State Metrics configuration files. And when I imported dashboards to Grafana - i was not able to get namespace's names, pod's names and etc.

5. You can get Slack API URL for Alert Manager using this tutorial:

https://api.slack.com/messaging/webhooks 


### Tutorials and Git repos that was used as a resource:

Ingress:

https://kubernetes.github.io/ingress-nginx/deploy/ 

Prometheus:
               
https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/
https://www.metricfire.com/blog/how-to-deploy-prometheus-on-kubernetes/
https://github.com/bibinwilson/kubernetes-prometheus



Kube-State-Metric: 
                      
https://devopscube.com/setup-kube-state-metrics/
https://github.com/bibinwilson/kube-state-metrics



Node Exporter: 

https://devopscube.com/node-exporter-kubernetes/
https://github.com/bibinwilson/kubernetes-node-exporter


Alert Manager:   
https://devopscube.com/alert-manager-kubernetes-guide/
https://github.com/bibinwilson/kubernetes-alert-manager



Grafana:

https://devopscube.com/setup-grafana-kubernetes/
https://github.com/bibinwilson/kubernetes-grafana

Grafana dashboards:

https://grafana.com/grafana/dashboards


### Grafana - Importing Dashboards Guide
https://rudimartinsen.com/2020/08/06/grafana-importing-dashboards/


Ingress-Nginx dashboard:

https://grafana.com/grafana/dashboards/14314

Node dashboards:

https://grafana.com/grafana/dashboards/315

https://grafana.com/grafana/dashboards/6417

https://grafana.com/grafana/dashboards/6126

https://grafana.com/grafana/dashboards/11802

Pod dashboard:

https://grafana.com/grafana/dashboards/6781

https://grafana.com/grafana/dashboards/9144



To get Slack API URL:
https://api.slack.com/messaging/webhooks 
