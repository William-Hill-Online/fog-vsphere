module Fog
  module Compute
    class Vsphere
      class Real
        def destroy_rule(attributes = {})
          cluster = get_raw_cluster(attributes[:cluster], attributes[:datacenter])
          rule    = cluster.configurationEx.rule.find {|rule| rule.key == attributes[:key]}
          raise Fog::Vsphere::Error::NotFound, "rule #{attributes[:key]} not found" unless rule
          delete_spec = RbVmomi::VIM.ClusterConfigSpecEx(rulesSpec: [
            RbVmomi::VIM.ClusterRuleSpec(
              operation: RbVmomi::VIM.ArrayUpdateOperation('remove'),
              removeKey: rule.key
            )
          ])
          cluster.ReconfigureComputeResource_Task(spec: delete_spec, modify: true).wait_for_completion
        end
      end
    end
  end
end
