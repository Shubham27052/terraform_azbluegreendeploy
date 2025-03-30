**Zero Downtime Blue-Green Deployment with Terraform**

Blue-Green deployments allow you to roll out a new version of your application with minimal downtime. I performed a **Blue-Green Deployment** using Terraform with **ZERO DOWNTIME**.

Setup (on Azure) Included:

1. A public **Load Balancer**
2. A single **Virtual Machine** running a simple application
3. VM is part of the Load Balancer **backend pool**
4. Application accessed over **HTTP**

If I simply change the VM image and **redeploy the VM** using Terraform, it will cause downtime. This is because Terraform will first **delete** the existing VM and then recreate it. This is not a suitable method as the VM will be unavailable for some time.

We need a way in Terraform to **first create the replacement VM and then delete the old (Blue) VM**.

I used the **`lifecycle` meta-argument** with `create_before_destroy` set to `true`. This ensured that:

1. First, the **Green VM** is created.
2. The **Green VM** is added to the backend pool.
3. Finally, the **Blue VM** is deleted.

This way, I could roll out the new version with **zero downtime**.

I tracked the downtime with a simple bash script that tracked the HTTP response status at a second interval. 

#Azure #Terraform #Cloud #DevOps

![image.png](attachment:85777fb8-4b8e-49f2-a413-3e2c32be9632:image.png)
