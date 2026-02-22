# Enterprise Networking Architecture

## Overview

This Control Tower deployment includes enterprise-grade centralized networking with AWS Transit Gateway, AWS Network Firewall, DNS Firewall, and comprehensive traffic inspection capabilities.

## Network Architecture

### Hub-and-Spoke Topology

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Transit Gateway Hub                           │
│                                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ Shared Svcs  │  │  Production  │  │ Non-Prod RT  │              │
│  │ Route Table  │  │ Route Table  │  │              │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│         │                  │                  │                      │
│         └──────────────────┴──────────────────┘                     │
│                            │                                         │
│                   ┌────────┴────────┐                               │
│                   │  Inspection RT  │                               │
│                   └─────────────────┘                               │
└─────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Inspection VPC                                  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              AWS Network Firewall (3 AZs)                    │   │
│  │  • Stateful/Stateless Rules                                 │   │
│  │  • Domain Filtering                                          │   │
│  │  • Threat Signatures                                         │   │
│  │  • IDS/IPS Capabilities                                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                            │                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Route 53 DNS Firewall                           │   │
│  │  • Malicious Domain Blocking                                │   │
│  │  • DNS Query Logging                                         │   │
│  │  • Allow/Deny Lists                                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                            │                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              NAT Gateways (3 AZs)                            │   │
│  │  • High Availability                                         │   │
│  │  • Elastic IPs                                               │   │
│  │  • Bandwidth Monitoring                                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                            │                                         │
└────────────────────────────┼─────────────────────────────────────────┘
                            │
                            ▼
                    Internet Gateway
                            │
                            ▼
                        Internet
```

## Components

### 1. AWS Transit Gateway

**Purpose**: Central hub for inter-VPC and on-premises connectivity

**Features:**
- Multi-account VPC connectivity
- Centralized routing
- VPN and Direct Connect integration
- ECMP support for high availability
- Private ASN: 64512 (configurable)

**Route Tables:**

1. **Shared Services Route Table**
   - Connects to shared infrastructure VPCs
   - DNS, Active Directory, monitoring
   - Accessible from all environments

2. **Production Route Table**
   - Production workload VPCs
   - Isolated from non-production
   - Strict security controls

3. **Non-Production Route Table**
   - Development, testing, staging VPCs
   - Isolated from production
   - More permissive for development

4. **Inspection Route Table**
   - Routes all traffic through Network Firewall
   - Centralized inspection point
   - Appliance mode enabled

**Traffic Flow:**
```
Spoke VPC → TGW → Inspection VPC → Network Firewall → NAT Gateway → Internet
```

### 2. Inspection VPC

**CIDR**: 10.0.0.0/16 (configurable)

**Subnet Design (per AZ):**

| Subnet Type | CIDR | Purpose |
|-------------|------|---------|
| Firewall | /20 | Network Firewall endpoints |
| Transit Gateway | /20 | TGW attachments |
| Public | /20 | NAT Gateways, IGW |

**High Availability:**
- 3 Availability Zones
- Redundant Network Firewall endpoints
- Multiple NAT Gateways
- Automatic failover

### 3. AWS Network Firewall

**Deployment:**
- Stateful firewall service
- Deployed across 3 AZs
- Managed by AWS
- Auto-scaling capacity

**Rule Groups:**

#### Stateless Rules
- **Priority 1**: Allow ICMP
  - Permits ping for troubleshooting
  - Pass to stateful engine

#### Stateful Rules

**1. Domain Allow List**
- Permitted domains:
  - *.amazonaws.com (AWS services)
  - *.aws.amazon.com (AWS console)
  - *.cloudfront.net (CDN)
  - .github.com (Source control)
  - .docker.com (Container registry)
  - .npmjs.org (Package manager)
  - .pypi.org (Python packages)
  - Custom domains (configurable)

**2. Domain Deny List**
- Blocked domains (configurable)
- Known malicious sites
- Unauthorized services
- Data exfiltration targets

**3. Threat Signatures**
- Malware C2 detection
- Backdoor port blocking (4444, 5555)
- SSH connection monitoring (port 22)
- RDP connection monitoring (port 3389)
- Custom Suricata rules

**Rule Processing:**
- Strict order evaluation
- Deny rules processed first
- Allow rules processed second
- Default action: Drop

**Logging:**
- Alert logs → CloudWatch Logs
- Flow logs → CloudWatch Logs + S3
- Real-time analysis
- Long-term retention

### 4. Route 53 DNS Firewall

**Purpose**: DNS-level threat protection

**Features:**
- Query-time domain filtering
- Malicious domain blocking
- DNS query logging
- Integration with threat intelligence

**Rule Groups:**

**1. Block Malicious Domains (Priority 100)**
- Action: BLOCK (NXDOMAIN response)
- Configurable domain list
- Threat intelligence feeds
- Known malware domains

**2. Allow Trusted Domains (Priority 200)**
- Action: ALLOW
- AWS service domains
- Approved third-party services
- Internal domains

**DNS Query Logging:**
- All queries logged to CloudWatch
- Source IP, query name, query type
- Response code, response data
- Firewall rule action

### 5. NAT Gateways

**Configuration:**
- One per Availability Zone (3 total)
- Elastic IP per NAT Gateway
- Automatic failover
- Bandwidth monitoring

**Features:**
- High availability
- Automatic scaling
- No management overhead
- CloudWatch metrics

**Monitoring:**
- Bytes in/out
- Packets in/out
- Connection count
- Error count
- Bandwidth alarms

### 6. VPC Flow Logs

**Capture:**
- All network traffic
- Accepted and rejected packets
- Source/destination IPs and ports
- Protocol and action

**Destinations:**
- CloudWatch Logs (real-time)
- S3 (long-term storage)
- Athena (analysis)

**Use Cases:**
- Security analysis
- Troubleshooting
- Compliance auditing
- Cost optimization

### 7. Network Access Analyzer

**Purpose**: Identify unintended network access

**Analysis:**
- Internet Gateway to EC2 paths
- Cross-account access
- Public subnet exposure
- Security group misconfigurations

**Findings:**
- Overly permissive rules
- Unintended public access
- Missing security controls
- Compliance violations

## Traffic Flows

### Outbound Internet Traffic

```
Workload VPC
    │
    ▼
Transit Gateway
    │
    ▼
Inspection VPC (TGW Subnet)
    │
    ▼
Network Firewall (Firewall Subnet)
    │ (Inspected & Filtered)
    ▼
NAT Gateway (Public Subnet)
    │
    ▼
Internet Gateway
    │
    ▼
Internet
```

### Inbound Internet Traffic (Optional)

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Network Firewall (Firewall Subnet)
    │ (Inspected & Filtered)
    ▼
Transit Gateway
    │
    ▼
Workload VPC
```

### VPC-to-VPC Traffic

```
Source VPC
    │
    ▼
Transit Gateway
    │
    ▼
Inspection VPC
    │
    ▼
Network Firewall (Inspection)
    │
    ▼
Transit Gateway
    │
    ▼
Destination VPC
```

### DNS Resolution

```
Workload Instance
    │
    ▼
Route 53 Resolver
    │
    ▼
DNS Firewall (Filter)
    │
    ▼
Route 53 Resolver (Forward)
    │
    ▼
Authoritative DNS
```

## Security Features

### Defense in Depth

**Layer 1: Network Segmentation**
- VPC isolation
- Subnet isolation
- Security groups
- NACLs

**Layer 2: Transit Gateway**
- Route table isolation
- Attachment policies
- Prefix list filtering

**Layer 3: Network Firewall**
- Stateful inspection
- Domain filtering
- Threat signatures
- IDS/IPS

**Layer 4: DNS Firewall**
- Query-time filtering
- Malicious domain blocking
- Query logging

**Layer 5: VPC Flow Logs**
- Traffic monitoring
- Anomaly detection
- Forensic analysis

### Threat Protection

**Network-Level Threats:**
- DDoS mitigation (AWS Shield)
- Malware C2 blocking
- Port scanning detection
- Brute force detection

**Application-Level Threats:**
- SQL injection (via WAF)
- XSS attacks (via WAF)
- Bot traffic (via WAF)

**DNS-Level Threats:**
- DNS tunneling
- Domain generation algorithms
- Malicious domain access
- Data exfiltration via DNS

### Compliance

**Logging Requirements:**
- All network traffic logged
- DNS queries logged
- Firewall decisions logged
- 7-year retention

**Audit Trail:**
- CloudTrail for API calls
- VPC Flow Logs for traffic
- DNS query logs
- Network Firewall logs

**Encryption:**
- TLS 1.2+ for all traffic
- VPN encryption for site-to-site
- KMS encryption for logs

## High Availability

### Multi-AZ Design

**Components per AZ:**
- Network Firewall endpoint
- NAT Gateway
- Transit Gateway attachment
- Subnets

**Failover:**
- Automatic AZ failover
- No manual intervention
- Sub-second detection
- Transparent to applications

### Redundancy

**Network Firewall:**
- Multiple endpoints
- Automatic scaling
- Health checks
- Traffic distribution

**NAT Gateways:**
- One per AZ
- Independent failure domains
- Automatic failover
- No single point of failure

**Transit Gateway:**
- Multi-AZ by design
- Automatic failover
- ECMP support
- 50 Gbps per AZ

## Monitoring and Alerting

### CloudWatch Metrics

**Network Firewall:**
- Packets processed
- Packets dropped
- Bytes processed
- Rule matches

**NAT Gateway:**
- Bytes in/out
- Packets in/out
- Connection count
- Error count

**Transit Gateway:**
- Bytes in/out
- Packets in/out
- Packet drop count
- Attachment count

### CloudWatch Alarms

**1. NAT Gateway Bandwidth**
- Threshold: 10 GB in 5 minutes
- Action: SNS notification
- Use case: Cost control, capacity planning

**2. Firewall Packet Drop**
- Threshold: 1000 packets in 5 minutes
- Action: SNS notification
- Use case: Security incident, misconfiguration

**3. DNS Query Anomalies**
- Threshold: Configurable
- Action: SNS notification
- Use case: DNS tunneling, DGA detection

### Log Analysis

**CloudWatch Logs Insights Queries:**

**Top Blocked Domains:**
```sql
fields @timestamp, domain, action
| filter action = "BLOCK"
| stats count() by domain
| sort count desc
| limit 10
```

**Top Talkers:**
```sql
fields @timestamp, srcaddr, dstaddr, bytes
| stats sum(bytes) as total_bytes by srcaddr
| sort total_bytes desc
| limit 10
```

**Firewall Rule Matches:**
```sql
fields @timestamp, rule_group, rule_name
| stats count() by rule_name
| sort count desc
```

## Cost Optimization

### Network Firewall Costs

**Pricing (ap-southeast-2):**
- Firewall endpoint: $0.395/hour per AZ
- Data processing: $0.065/GB

**Monthly Cost (3 AZs):**
- Base: ~$850/month (3 endpoints × 730 hours)
- Data: Variable based on traffic

**Optimization:**
- Right-size rule groups
- Use stateless rules where possible
- Optimize domain lists
- Monitor data processing

### NAT Gateway Costs

**Pricing (ap-southeast-2):**
- NAT Gateway: $0.059/hour
- Data processing: $0.059/GB

**Monthly Cost (3 AZs):**
- Base: ~$130/month (3 gateways × 730 hours)
- Data: Variable based on traffic

**Optimization:**
- Use VPC endpoints for AWS services
- Implement caching
- Optimize data transfer
- Consider PrivateLink

### Transit Gateway Costs

**Pricing (ap-southeast-2):**
- Attachment: $0.07/hour
- Data transfer: $0.02/GB

**Monthly Cost:**
- Variable based on attachments and traffic

**Optimization:**
- Consolidate VPCs where possible
- Use VPC peering for high-volume pairs
- Implement data transfer optimization
- Monitor attachment usage

### Total Estimated Monthly Cost

**Base Infrastructure:**
- Network Firewall: $850
- NAT Gateways: $130
- Transit Gateway: $50-200 (varies)
- **Total Base: ~$1,030-1,180/month**

**Variable Costs:**
- Data processing: $0.065-0.13/GB
- Depends on traffic volume

## Deployment

### Prerequisites

1. **Network Planning**
   - CIDR allocation
   - Subnet design
   - Route table planning
   - DNS architecture

2. **Security Requirements**
   - Firewall rules
   - Domain lists
   - Threat signatures
   - Compliance needs

3. **High Availability**
   - AZ selection
   - Redundancy requirements
   - Failover testing

### Deployment Steps

1. **Enable Centralized Networking**
```hcl
enable_centralized_networking = true
```

2. **Configure Network Settings**
```hcl
inspection_vpc_cidr = "10.0.0.0/16"
network_availability_zones = [
  "ap-southeast-2a",
  "ap-southeast-2b",
  "ap-southeast-2c"
]
```

3. **Define Firewall Rules**
```hcl
network_firewall_allowed_domains = [
  ".github.com",
  ".docker.com"
]
```

4. **Deploy Infrastructure**
```bash
terraform apply
```

### Post-Deployment

1. **Attach Workload VPCs**
   - Create TGW attachments
   - Associate with route tables
   - Update VPC route tables

2. **Test Connectivity**
   - Verify internet access
   - Test VPC-to-VPC
   - Validate DNS resolution

3. **Configure Monitoring**
   - Set up dashboards
   - Configure alarms
   - Test notifications

4. **Security Validation**
   - Test firewall rules
   - Verify DNS filtering
   - Review logs

## Operations

### Daily Tasks

1. **Monitor Dashboards**
   - Network Firewall metrics
   - NAT Gateway bandwidth
   - Transit Gateway health

2. **Review Logs**
   - Firewall alerts
   - DNS query anomalies
   - VPC Flow Logs

3. **Check Alarms**
   - Bandwidth alerts
   - Packet drop alerts
   - Connection failures

### Weekly Tasks

1. **Log Analysis**
   - Top blocked domains
   - Traffic patterns
   - Cost analysis

2. **Rule Review**
   - Firewall rule effectiveness
   - DNS filter accuracy
   - False positive analysis

3. **Capacity Planning**
   - Bandwidth trends
   - Connection counts
   - Growth projections

### Monthly Tasks

1. **Security Review**
   - Threat landscape changes
   - Rule updates
   - Signature updates

2. **Cost Optimization**
   - Data transfer analysis
   - Unused resources
   - Right-sizing opportunities

3. **Compliance Audit**
   - Log retention verification
   - Encryption validation
   - Access control review

## Troubleshooting

### Common Issues

**1. No Internet Connectivity**
- Check NAT Gateway status
- Verify route tables
- Check Network Firewall rules
- Review security groups

**2. Slow Network Performance**
- Check NAT Gateway bandwidth
- Review Network Firewall metrics
- Analyze VPC Flow Logs
- Check Transit Gateway limits

**3. DNS Resolution Failures**
- Check DNS Firewall rules
- Verify Route 53 Resolver
- Review DNS query logs
- Check VPC DNS settings

**4. High Costs**
- Analyze data transfer
- Review NAT Gateway usage
- Check Network Firewall processing
- Optimize traffic patterns

### Diagnostic Commands

**Check NAT Gateway:**
```bash
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available"
```

**Check Network Firewall:**
```bash
aws network-firewall describe-firewall \
  --firewall-name <name>
```

**Check Transit Gateway:**
```bash
aws ec2 describe-transit-gateways
```

**View VPC Flow Logs:**
```bash
aws logs tail /aws/vpc/flow-logs/<vpc-id> --follow
```

## Best Practices

### Security

1. **Least Privilege**
   - Minimal firewall rules
   - Specific domain lists
   - Deny by default

2. **Defense in Depth**
   - Multiple security layers
   - Redundant controls
   - Fail-secure design

3. **Continuous Monitoring**
   - Real-time alerting
   - Log analysis
   - Threat hunting

### Performance

1. **Right-Sizing**
   - Appropriate NAT Gateway count
   - Optimal firewall rules
   - Efficient routing

2. **Caching**
   - DNS caching
   - Content caching
   - Connection pooling

3. **Optimization**
   - VPC endpoints for AWS services
   - Direct Connect for on-premises
   - CloudFront for content delivery

### Cost

1. **Monitoring**
   - Track data transfer
   - Monitor bandwidth
   - Analyze patterns

2. **Optimization**
   - Use VPC endpoints
   - Implement caching
   - Consolidate traffic

3. **Planning**
   - Forecast growth
   - Budget allocation
   - Cost allocation tags

## References

- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [AWS Network Firewall](https://docs.aws.amazon.com/network-firewall/)
- [Route 53 Resolver DNS Firewall](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver-dns-firewall.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
