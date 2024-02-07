import * as awsx from "@pulumi/awsx";
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as fs from "fs";

// VPC
const vpc = new awsx.ec2.Vpc("pulumi-vpc", {
    cidrBlock: "172.31.0.0/16",
    enableDnsHostnames: true,
    numberOfAvailabilityZones: 2, 
    subnetSpecs: [
        { 
            type: "Private" 
        },
        { 
            type: "Public" 
        },
    ],
});

export const vpcId = vpc.vpcId;
export const privateSubnetIds = vpc.privateSubnetIds;
export const publicSubnetIds = vpc.publicSubnetIds;


const securityGroup = new aws.ec2.SecurityGroup("pulumi-security-group", {
    vpcId: vpc.vpcId,
    ingress: [
        {
            fromPort: 22,
            toPort: 22,
            protocol: "tcp",
            cidrBlocks: ["0.0.0.0/0"],
            ipv6CidrBlocks: ["::/0"],
        }
    ],
    egress: [
        {
            fromPort: 0,
            toPort: 0,
            protocol: "-1",
            cidrBlocks: ["0.0.0.0/0"],
            ipv6CidrBlocks: ["::/0"],
        },
    ],
});


// EC2
const ubuntuAMI = aws.ec2.getAmi({
    filters: [{
        name: "name",
        values: ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"],
    }],
    owners: ["099720109477"],
    mostRecent: true,
}).then(ami => ami.imageId);

const userData = fs.readFileSync("userdata.sh");

const instance = new aws.ec2.Instance("instance", {
    ami: ubuntuAMI, 
    instanceType: "m6a.2xlarge",
    vpcSecurityGroupIds: [securityGroup.id], 
    subnetId: publicSubnetIds[0],
    userData: userData.toString(),
    keyName: "aws-ec2-key",
    rootBlockDevice: {
        volumeSize: 1050, 
        volumeType: "gp3"
      },
  tags: {
      "Name": "pokt001"
  },
});

