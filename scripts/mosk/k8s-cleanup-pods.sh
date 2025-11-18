#!/usr/bin/env bash
kubectl delete pod --field-selector=status.phase=Succeeded $@
