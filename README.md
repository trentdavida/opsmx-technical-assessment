# opsmx-technical-assessment
Ops Mx Technical Assessment

## Execution
on Ubuntu 16/18

`wget -O install.sh https://raw.githubusercontent.com/trentdavida/opsmx-technical-assessment/master/install.sh && chmod +x install.sh && ./install.sh`

## Explanation
One-liner because why not. User should have sudo privileges.

First the script will install apt-transport-https, cUrl, and software-properties-common. Then, if not found, it will install docker and Kubernetes, for the system's release version, using stable and main sources respectively. Next it downloads and builds the dockerfile if the image isn't found. Then it will apply ip-responder.yaml and wait for the pod to have the status of "Running". Finally it attempts to curl 0.0.0.0:30080 checking for the IP message, and reporting either a Success or Failure and exiting with the cooresponding exit code.

## Testing
Manaul testing can be completed by cUrl-ing local port 30080: `curl 0.0.0.0:30080`
Demo responds with IP of the Requestor.
