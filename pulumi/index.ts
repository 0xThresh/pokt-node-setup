import * as awsx from "@pulumi/awsx";
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as fs from "fs";
import * as dotenv from "dotenv";

// Load variables from .env
dotenv.config();

//const VALID_NODE_TYPES = ['VALIDATOR', 'SERVICER', 'FULL_NODE']

// Retrieve config from .env variables
const DNS_HOSTNAME = process.env.DNS_HOSTNAME as string;
const POCKET_ACCOUNT_PASSWORD = process.env.POCKET_ACCOUNT_PASSWORD as string;

// Validate that the hostname is properly loaded from .env
if (!DNS_HOSTNAME) {
    throw new Error("The DNS_HOSTNAME environment variable must be set in the .env file.");
  }

// Validate that a password is set for Pocket account
if (!POCKET_ACCOUNT_PASSWORD) {
    throw new Error("The POCKET_ACCOUNT_PASSWORD environment variable must be set in the .env file.");
  }

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
            description: "SSH"
        },
        {
            fromPort: 80,
            toPort: 80,
            protocol: "tcp",
            cidrBlocks: ["0.0.0.0/0"],
            ipv6CidrBlocks: ["::/0"],
            description: "HTTP"
        },
        {
            fromPort: 443,
            toPort: 443,
            protocol: "tcp",
            cidrBlocks: ["0.0.0.0/0"],
            ipv6CidrBlocks: ["::/0"],
            description: "HTTPS"
        },
        {
            fromPort: 8081,
            toPort: 8081,
            protocol: "tcp",
            cidrBlocks: ["0.0.0.0/0"],
            ipv6CidrBlocks: ["::/0"],
            description: "Pocket HTTP API"
        },
        {
            fromPort: 26656,
            toPort: 26656,
            protocol: "tcp",
            cidrBlocks: ["0.0.0.0/0"],
            ipv6CidrBlocks: ["::/0"],
            description: "Pocket RPC API"
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

const userDataTemplate = fs.readFileSync("userdata.sh", "utf8");
const userData = userDataTemplate.replace("${DNS_HOSTNAME}", DNS_HOSTNAME);

const instance = new aws.ec2.Instance("instance", {
    ami: ubuntuAMI, 
    instanceType: "m6a.xlarge",
    vpcSecurityGroupIds: [securityGroup.id], 
    subnetId: publicSubnetIds[0],
    //userData: userData.toString(),
    keyName: process.env.EC2_KEY_NAME,
    // TODO: Change root volume size based on node type 
    rootBlockDevice: {
        volumeSize: 150, 
        volumeType: "gp3"
      },
  tags: {
      "Name": "pokt"
  },
});

// Route53 Record
const r53_zone = aws.route53.getZone({
    name: DNS_HOSTNAME,
    privateZone: false,
}).then(r53_zone => r53_zone.id);
;

const pokt = new aws.route53.Record("pokt", {
    zoneId: r53_zone,
    name: `pokt.${DNS_HOSTNAME}`,
    type: "A",
    ttl: 300,
    records: [instance.publicIp],
});