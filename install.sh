#!/bin/bash

if [ "$(id -u)" = "0" ]; then
        echo -e "\nPlease run this script as non-root user without using sudo.\n    The script will ask for sudo when necessary.\n"
        exit 1
fi

echo -e "Installing Prerequisites\n"
sudo apt update && sudo apt install -y apt-transport-https && \
sudo apt update && sudo apt install -y curl software-properties-common

#Check for Docker
echo -e "\nChecking for Docker: ";
if [[ $(which docker) && $(docker --version) ]]; then
    echo -e "Found $(docker --version)\n";
else
    echo -e "Installing docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    sudo apt update && sudo apt install -y docker-ce && \
    cat > /tmp/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
    sudo mv /tmp/daemon.json /etc/docker/daemon.json && \
    sudo mkdir -p /etc/systemd/system/docker.service.d && \
    sudo systemctl daemon-reload && sudo systemctl restart docker && \
    echo -e "\nInstalled $(docker --version)" && \
    \
    echo -e "\nDisabling Swap: " && \
    sudo swapoff -a && sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && \
    echo -e "Swap Disabled.\n"
fi

#Check for Kubernetes
echo -e "\nChecking for Kubernetes: "
if [[ $(which kubeadm) && $(kubeadm version) ]]; then
    echo -e "Found $(kubeadm version)\n";
else
    echo -e "Installing Kubernetes"
    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" && \
    sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni && \
    echo -e "\nInstalled $(kubeadm version)" && \
    \
    echo -e "\nInitializing cluster: " && \
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU && \
    \
    echo -e "\nEnabling kubctl for $(whoami): " && \
    mkdir -p $HOME/.kube && \
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
    sudo chown $(id -u):$(id -g) $HOME/.kube/config && \
    \
    echo -e "\nApplying Flannel network configuration" && \
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml && \
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml && \
    \
    echo -e "\nConfiguring Kubernetes to allow deployments to master cluster." && \
    kubectl taint nodes --all node-role.kubernetes.io/master-
fi

#Check for Test Image
echo -e "\nChecking for Test Nginx Image: ";
if [[ $(sudo docker images | grep nginx-ip-responder) ]]; then
    echo -e "Found nginx-ip-responder image\n";
else
    echo -e "Building nginx-ip-responder image"
    curl -JLO https://raw.githubusercontent.com/trentdavida/opsmx-technical-assessment/master/Dockerfile && \
    sudo docker build -t nginx-ip-responder . && \
    rm Dockerfile
fi

#Deploy Image
echo -e "\nDeploying nginx-ip-responder to port 30080"
kubectl apply -f https://raw.githubusercontent.com/trentdavida/opsmx-technical-assessment/master/ip-responder.yaml
until $(kubectl get pods -l app=ip-responder | grep -q Running); do
    echo "Waiting for pod to Start.";
    sleep 5;
done

#Test Deployment
echo -e "\nTesting service at 0.0.0.0:30080"
curl 0.0.0.0:30080 > output.txt
if grep "Your IP Address is " "output.txt"; then
  echo -e "\nSuccess!\n\nDeployment Complete.";
  exit 0;
else
  echo -e "\nFailure. Test produced unexpected result: "
  cat output.txt;
  exit 1;
fi
