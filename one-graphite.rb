#! /usr/bin/ruby

##
 # one-graphite
 #
 # @author      Sebastian Mangelkramer
 #              2017
 #
 # Name:        one-graphite
 # Description: Parse OpenNebula XML to generate graphite metrics
 #
##



# gem install nokogiri
require 'nokogiri'

# gem install simple-graphite
require 'simple-graphite'

#
# Graphite Settings
#

g = Graphite.new
# Graphite Host
g.host = 'hostname.of.graphite.server'
# Graphite Port
g.port = 2003


# Metric Prefix
prefix="opennebula-performance"

# OpenNebula Zone ID
zone="opennebula-zone-name"

#
# VMM Host Performance Data / onehost performance
#
one_performance = Nokogiri::XML.parse(`onehost list -x`)
one_performance.xpath('//HOST').each do |host_element|

    # host performance data
    cluster     = host_element.xpath('CLUSTER').text
    host        = host_element.xpath('NAME').text.tr(".", "_")
    mem_usage   = host_element.xpath('HOST_SHARE/MEM_USAGE').text
    max_mem     = host_element.xpath('HOST_SHARE/MAX_MEM').text
    used_mem    = host_element.xpath('HOST_SHARE/USED_MEM').text
    free_mem    = host_element.xpath('HOST_SHARE/FREE_MEM').text
    cpu_usage   = host_element.xpath('HOST_SHARE/CPU_USAGE').text
    max_cpu     = host_element.xpath('HOST_SHARE/MAX_CPU').text
    used_cpu    = host_element.xpath('HOST_SHARE/USED_CPU').text
    free_cpu    = host_element.xpath('HOST_SHARE/FREE_CPU').text
    rvms        = host_element.xpath('HOST_SHARE/RUNNING_VMS').text

    # push metrics to graphite
    g.send_metrics({
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.mem_usage" => mem_usage,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.max_mem" => max_mem,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.used_mem" => used_mem,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.free_mem" => free_mem,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.cpu_usage" => cpu_usage,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.max_cpu" => max_cpu,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.used_cpu" => used_cpu,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.free_cpu" => free_cpu,
        "#{prefix}.zones.#{zone}.clusters.#{cluster}.hosts.#{host}.rvms" => rvms
    })
end

#
# VDC Performance Data / onegroup performance
#
onegroup_performance = Nokogiri::XML.parse(`onegroup list -x`)
onegroup_performance.xpath('//GROUP').each do |group_element|

    # graph performance data
    group_id = group_element.xpath('ID').text

    
    onegroup_performance.xpath('//QUOTAS').each do |quota_element|

        quota_id = quota_element.xpath('ID').text
        if quota_id == group_id
            group_name          = group_element.xpath('NAME').text
            group_cpu           = quota_element.xpath('VM_QUOTA/VM/CPU').text
            group_cpu_used      = quota_element.xpath('VM_QUOTA/VM/CPU_USED').text
            group_memory        = quota_element.xpath('VM_QUOTA/VM/MEMORY').text
            group_memory_used   = quota_element.xpath('VM_QUOTA/VM/MEMORY_USED').text
            group_vms           = quota_element.xpath('VM_QUOTA/VM/VMS').text
            group_vms_used      = quota_element.xpath('VM_QUOTA/VM/VMS_USED').text
            
            # Debug
            #puts "VDC: #{group_name}  CPU: #{group_cpu} /  #{group_cpu_used} MEMORY: #{group_memory} / #{group_memory_used} VM: #{group_vms} / #{group_vms_used}"
        
            # send out metrics to graphite
            g.send_metrics({
                "#{prefix}.zones.#{zone}.vdcs.#{group_name}.quotas.group_cpu" => group_cpu,
                "#{prefix}.zones.#{zone}.vdcs.#{group_name}.quotas.group_cpu_used" => group_cpu_used,
                "#{prefix}.zones.#{zone}.vdcs.#{group_name}.quotas.group_memory" => group_memory,
                "#{prefix}.zones.#{zone}.vdcs.#{group_name}.quotas.group_memory_used" => group_memory_used,
                "#{prefix}.zones.#{zone}.vdcs.#{group_name}.quotas.group_vms" => group_vms,
                "#{prefix}.zones.#{zone}.vdcs.#{group_name}.quotas.group_vms_used" => group_vms_used
            })

        end
    end
end

#
# VM Performance Data / onevm performance
#
onevm_performance = Nokogiri::XML.parse(`onevm list -x`)
onevm_performance.xpath('//VM').each do |vm_element|

	vm_id 		= vm_element.xpath('ID').text
	vm_diskrdiops 	= vm_element.xpath('MONITORING/DISKRDIOPS').text
	vm_diskrdbytes 	= vm_element.xpath('MONITORING/DISKRDBYTES').text
	vm_diskwriops 	= vm_element.xpath('MONITORING/DISKWRIOPS').text
	vm_diskwrbytes 	= vm_element.xpath('MONITORING/DISKWRBYTES').text
	vm_cpu 		= vm_element.xpath('MONITORING/CPU').text
	vm_netrx 	= vm_element.xpath('MONITORING/NETRX').text
	vm_nettx 	= vm_element.xpath('MONITORING/NETTX').text

	# Debug
	puts "VM: #{vm_id} CPU: #{vm_cpu}  NET-TX: #{vm_nettx} NET-RX: #{vm_netrx} RD-IOPS: #{vm_diskrdiops} RW-IOPS: #{vm_diskwriops}"

	# send out metrics to graphite
	g.send_metrics({
		"#{prefix}.zones.#{zone}.vms.#{vm_id}.monitoring.vm_diskrdiops" => vm_diskrdiops,
		"#{prefix}.zones.#{zone}.vms.#{vm_id}.monitoring.vm_diskwriops" => vm_diskwriops,
		"#{prefix}.zones.#{zone}.vms.#{vm_id}.monitoring.vm_diskwrbytes" => vm_diskwrbytes,
		"#{prefix}.zones.#{zone}.vms.#{vm_id}.monitoring.vm_diskrdbytes" => vm_diskrdbytes,
		"#{prefix}.zones.#{zone}.vms.#{vm_id}.monitoring.vm_netrx" => vm_netrx,
		"#{prefix}.zones.#{zone}.vms.#{vm_id}.monitoring.vm_nettx" => vm_nettx,
		"#{prefix}.zones.#{zone}.vms.#{vm_id}.monitoring.vm_cpu" => vm_cpu
	})

end
