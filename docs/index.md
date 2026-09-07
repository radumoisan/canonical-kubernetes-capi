# Canonical Kubernetes CAPI

This site contains the Canonical Kubernetes Cluster API training material, organized one chapter per page.

Start with [Chapter 1: Kubernetes Basics](1-kubernetes-basics.md), then [Chapter 2: Networking](2-networking.md), then [Chapter 3: Keeping apps healthy](3-keeping-apps-healthy.md), then [Chapter 4: Storage and User Data](4-storage-and-user-data.md), then [Chapter 5: Autoscaling](5-autoscaling.md), then [Chapter 6: Authentication and Authorization](6-authentication-and-authorization.md), then [Chapter 7: Helm](7-helm.md). Remaining chapters will be published in order.

## Copyright

This material is copyright of Canonical Limited. This material may be used for personal and noncommercial
use only.

This documentation is copyright of Canonical Limited. You are welcome to display on your
computer, download and print this documentation or to use the hard copy provided to you for
personal, education and non-commercial use only. You must retain copyright, trademark and
other notices unaltered on any copies or printouts you make. Any trademarks, logos an service
marks displayed in this document are property of their owners, whether Canonical or third
parties.

This documentation is provided on an "as is" basis, without warranty of any kind, either express
or implied. Your use of this documentation is at your own risk. Canonical disclaims all warranties
and liability that may result directly or indirectly from the use of this documentation.

## Lab assumptions

The following exercises will be done in a practice lab environment comprised of Virtual Machines on GCP cloud.
The instructor will provide you with a public IP and credentials for a student machine. SSH will be used to connect to
he student machine. The IP is static and reboot persistent.

The purpose of this lab is to familiarize the student with Kubernetes. Kubernetes version `1.35` will be deployed.
