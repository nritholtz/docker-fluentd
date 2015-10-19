# !/bin/bash

# Will lookup IP from EC2 instance host for logging purposes unless env_var DEBUG is set
if [ -z "$DEBUG" ]; then 
  export IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
# Get IP address from the container
else
  export IP_ADDRESS=$(awk 'NR==1 {print $1}' /etc/hosts)
fi

# Set default value to development for logging environment
if [ -z "$LOG_ENVIRONMENT" ]; then
  export LOG_ENVIRONMENT=development
fi

# Set AWS region for CloudWatch
if [ -z "$AWS_REGION" ]; then
  export AWS_REGION=us-east-1
fi



/usr/bin/supervisord -c supervisord.conf