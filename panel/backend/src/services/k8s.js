const k8s = require('@kubernetes/client-node');
const fs = require('fs');
const path = require('path');
const logger = require('../logger');

const TEMPLATES_DIR = path.join(__dirname, '../../../../k8s/tenant-templates');

/**
 * Use in-cluster config when running inside cluster; otherwise KUBECONFIG.
 * Do NOT rely on local kubeconfig when in cluster.
 */
function getKubeConfig() {
  const inCluster = !!(
    process.env.KUBERNETES_SERVICE_HOST &&
    process.env.KUBERNETES_SERVICE_PORT
  );
  const kc = new k8s.KubeConfig();
  try {
    if (inCluster) {
      kc.loadFromCluster();
      logger.debug('Using in-cluster Kubernetes config');
    } else {
      if (!process.env.KUBECONFIG) {
        throw new Error(
          'Not in cluster and KUBECONFIG is not set; cannot reach Kubernetes API'
        );
      }
      kc.loadFromFile(process.env.KUBECONFIG);
      logger.debug('Using KUBECONFIG', { path: process.env.KUBECONFIG });
    }
  } catch (err) {
    logger.error('Failed to load Kubernetes config', {
      error: err.message,
      inCluster,
    });
    throw err;
  }
  return kc;
}

/**
 * Provision tenant resources in order. On failure, rollback created resources.
 */
async function provisionTenant(id, namespace) {
  const tenantDomain = process.env.TENANT_DOMAIN || 'example.local';
  const kc = getKubeConfig();
  const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
  const appsApi = kc.makeApiClient(k8s.AppsV1Api);
  const netApi = kc.makeApiClient(k8s.NetworkingV1Api);

  const created = { namespace: false, resourceQuota: false, pvc: false, deployment: false, service: false, ingress: false };

  try {
    // 1. Namespace
    const nsRaw = fs.readFileSync(path.join(TEMPLATES_DIR, 'tenant-namespace.yaml'), 'utf8');
    const nsYaml = nsRaw.replace(/PLACEHOLDER_ID/g, id);
    const nsSpec = k8s.loadAllYaml(nsYaml)[0];
    await k8sApi.createNamespace(nsSpec);
    created.namespace = true;
    logger.info('Created tenant namespace', { id, namespace });

    // 2. ResourceQuota (in namespace)
    const rqRaw = fs.readFileSync(path.join(TEMPLATES_DIR, 'tenant-resource-quota.yaml'), 'utf8');
    const rqYaml = rqRaw.replace(/PLACEHOLDER_ID/g, id);
    const rqSpec = k8s.loadAllYaml(rqYaml)[0];
    await k8sApi.createNamespacedResourceQuota(namespace, rqSpec);
    created.resourceQuota = true;

    // 3. PVC
    const pvcRaw = fs.readFileSync(path.join(TEMPLATES_DIR, 'tenant-pvc.yaml'), 'utf8');
    const pvcYaml = pvcRaw.replace(/PLACEHOLDER_ID/g, id);
    const pvcSpec = k8s.loadAllYaml(pvcYaml)[0];
    await k8sApi.createNamespacedPersistentVolumeClaim(namespace, pvcSpec);
    created.pvc = true;

    // 4. Deployment + 5. Service (from tenant-nginx.yaml)
    const nginxRaw = fs.readFileSync(path.join(TEMPLATES_DIR, 'tenant-nginx.yaml'), 'utf8');
    const nginxYaml = nginxRaw.replace(/PLACEHOLDER_ID/g, id);
    const nginxSpecs = k8s.loadAllYaml(nginxYaml);
    for (const spec of nginxSpecs) {
      if (spec.kind === 'Deployment') {
        await appsApi.createNamespacedDeployment(namespace, spec);
        created.deployment = true;
      } else if (spec.kind === 'Service') {
        await k8sApi.createNamespacedService(namespace, spec);
        created.service = true;
      }
    }

    // 6. Ingress (dynamic host from env)
    const ingRaw = fs.readFileSync(path.join(TEMPLATES_DIR, 'tenant-ingress.yaml'), 'utf8');
    const ingYaml = ingRaw
      .replace(/PLACEHOLDER_ID/g, id)
      .replace(/PLACEHOLDER_TENANT_DOMAIN/g, tenantDomain);
    const ingSpec = k8s.loadAllYaml(ingYaml)[0];
    await netApi.createNamespacedIngress(namespace, ingSpec);
    created.ingress = true;

    logger.info('Tenant provisioned successfully', { id, namespace });
  } catch (err) {
    logger.error('Tenant provisioning failed, rolling back', {
      id,
      namespace,
      error: err.message,
      created,
    });
    await rollbackTenant(k8sApi, appsApi, netApi, namespace, created);
    throw err;
  }
}

async function rollbackTenant(k8sApi, appsApi, netApi, namespace, created) {
  const opts = { propagationPolicy: 'Background' };
  try {
    if (created.ingress) {
      await netApi.deleteNamespacedIngress('tenant-ingress', namespace).catch(() => {});
    }
    if (created.service) {
      await k8sApi.deleteNamespacedService('nginx', namespace).catch(() => {});
    }
    if (created.deployment) {
      await appsApi.deleteNamespacedDeployment('nginx', namespace, undefined, undefined, undefined, undefined, opts).catch(() => {});
    }
    if (created.pvc) {
      await k8sApi.deleteNamespacedPersistentVolumeClaim('tenant-data', namespace).catch(() => {});
    }
    if (created.resourceQuota) {
      await k8sApi.deleteNamespacedResourceQuota('tenant-quota', namespace).catch(() => {});
    }
    if (created.namespace) {
      await k8sApi.deleteNamespace(namespace, undefined, undefined, undefined, undefined, opts).catch(() => {});
    }
    logger.info('Rollback completed', { namespace });
  } catch (e) {
    logger.error('Rollback error', { namespace, error: e.message });
  }
}

module.exports = { provisionTenant, getKubeConfig };
