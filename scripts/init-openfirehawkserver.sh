echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"
cd /vagrant
ansible-playbook -i ansible/inventory/hosts ansible/init.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/openfirehawkserver_houdini.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml -v
#reboot
# terraform apply --auto-approve