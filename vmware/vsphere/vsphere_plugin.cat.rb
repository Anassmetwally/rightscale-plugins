name 'VMware VSphere Plugin'
short_description 'A RightScale Self-Service plugin for VMware Vsphere'
long_description 'Version 1.0'
rs_ca_ver 20161221
type 'plugin'
package 'plugins/rs_vmware_vsphere'

import 'sys_log'

# requires vcenter > 6.0

plugin 'rs_vmware_vsphere' do
  endpoint do
    default_host 'wstunnel'
    default_scheme 'https'

    # Insert your wstunnel token here
    # Currently it's hard coded
    path "/_token/<token>"

    headers do {
      'User-Agent' => 'RightScale Self-Service/20161221'
    } end

    # unfortunately, very common to be using self-signed or
    # not a public CA
    no_cert_check true
  end
  
  type 'cis_tagging_category' do
    href_templates "/rest/com/vmware/cis/tagging/category/id:$value"
    provision "provision_resource"
    delete "delete_resource"

    field "name" do
      type "string"
    end

    field "description" do
      type "string"
    end

    field "cardinality" do
      type "string"
    end

    field "associable_types" do
      type "array"
    end

    action "create" do
      type "cis_tagging_category"
      path "/rest/com/vmware/cis/tagging/category"
      verb "POST"
    end

    action "update" do
      type "cis_tagging_category"
      path "$href"
      verb "PATCH"
    end

    action "destroy" do
      type "cis_tagging_category"
      path "$href"
      verb "DELETE"
    end

    action "list" do
      type "cis_tagging_category"
      path "/rest/com/vmware/cis/tagging/category"
      verb "GET"
    end

    output "value"
  end

  type 'cis_tagging_tag' do
    href_templates "/rest/com/vmware/cis/tagging/tag/id:$value"
    provision "provision_resource"
    delete "delete_resource"

    field "name" do
      type "string"
    end

    field "category_id" do
      type "string"
    end

    field "description" do
      type "string"
    end

    action "create" do
      type "cis_tagging_tag"
      path "/rest/com/vmware/cis/tagging/tag"
      verb "POST"
    end

    action "update" do
      type "cis_tagging_category"
      path "$href"
      verb "PATCH"
    end

    action "destroy" do
      type "cis_tagging_category"
      path "$href"
      verb "DELETE"
    end

    action "list" do
      type "cis_tagging_category"
      path "/rest/com/vmware/cis/tagging/tag"
      verb "GET"
    end

    action "attach" do
      path "/rest/com/vmware/cis/tagging/tag-association/id:$name?~action=attach"
    end

    action "detach" do
      path "/rest/com/vmware/cis/tagging/tag-association/id:$name?~action=detach"
    end

    output "value"
  end

  type 'vcenter_vm_hardware_disk' do
    provision "provision_resource"
    delete "delete_resource"
  end
end

##
# Resource Pool(s)
###
resource_pool 'vmware_vsphere' do
  plugin $vmware_vsphere

  host "j2xrp.herokuapp.com"

  auth 'nsx_auth', type: 'basic' do
    username cred('NSX_USER')
    password cred('NSX_PASSWORD')
  end
end

define start_debugging() do
  if $$debugging == false || logic_and($$debugging != false, $$debugging != true)
    initiate_debug_report()
    $$debugging = true
  end
end

define stop_debugging() do
  if $$debugging == true
    $debug_report = complete_debug_report()
    call sys_log.detail($debug_report)
    $$debugging = false
  end
end

###
# Provisioning Definitions
###
define provision_resource(@declaration) return @resource on_error: stop_debugging() do
  sub on_error: stop_debugging() do
    $object = to_object(@declaration)
    $fields = $object["fields"]
    $type = $object["type"]
    call sys_log.set_task_target(@@deployment)
    call sys_log.summary(join(["Provision ", $type]))
    call sys_log.detail($object)
    call start_debugging()
    @operation = rs_vmware_vsphere.$type.create($fields)
    call stop_debugging()
    call sys_log.detail(to_object(@operation))
    call start_debugging()
    @resource = @operation.get()
    call stop_debugging()
    call sys_log.detail(to_object(@resource))
  end
end

define delete_resource(@resource) do
  call sys_log.set_task_target(@@deployment)
  $resource = to_object(@resource)
  $type = $resource["type"]
  call sys_log.summary(join(["Delete Resource ",$type]))
  if !empty?(@resource)
    call sys_log.detail("Resource Exists")
    sub on_error: skip_not_found_error() do
      call start_debugging()
      @resource.destroy()
      call stop_debugging()
    end
  else
    call sys_log.detail("Resource Does Not Exist")
  end
end

define skip_not_found_error() do
  call stop_debugging()
  if $_error["message"] =~ "/could not be found/i"
    call sys_log.detail($_error["type"] + ": " + $_error["message"])
    $_error_behavior = "skip"
  end
end