#!/bin/bash
istioctl install -y --set meshConfig.defaultConfig.tracing.zipkin.address=simplest-collector.monitoring.svc.cluster.local:9411 
