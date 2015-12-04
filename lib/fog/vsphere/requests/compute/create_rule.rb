module Fog
  module Compute
    class Vsphere
      class Real
        def create_rule(attributes={})
          cluster = get_raw_cluster(attributes[:cluster], attributes[:datacenter])
          # Check if it already exists and blow up if it does
          # (otherwise ESX just happily accepts it and then considers it a conflict)
          rule = cluster.configurationEx.rule.find {|n| n[:name] == attributes[:name]}
          if rule
              raise ArgumentError, "Rule #{attributes[:name]} already exists!"
          end
          # First, create the rulespec
          vms = attributes[:vm_ids].to_a.map {|id| get_vm_ref(id, attributes[:datacenter])}
          spec = attributes[:type].new(
            name: attributes[:name],
            enabled: attributes[:enabled],
            vm: vms
          )
          # Now, attach it to the cluster
          cluster_spec = RbVmomi::VIM.ClusterConfigSpecEx(rulesSpec: [
            RbVmomi::VIM.ClusterRuleSpec(
              operation: RbVmomi::VIM.ArrayUpdateOperation('add'),
              info: spec
            )
          ])
          ret = cluster.ReconfigureComputeResource_Task(spec: cluster_spec, modify: true).wait_for_completion
          rule = cluster.configurationEx.rule.find {|n| n[:name] == attributes[:name]}
          if rule
            return rule[:key]
          else
            raise Fog::Vsphere::Errors::ServiceError, "Unknown error creating rule #{attributes[:name]}"
          end
        end
        
      end
      class Mock
        def create_rule(attributes={})
          attributes[:key] = rand(9999)
          self.data[:rules][attributes[:name]] = attributes
          attributes[:key]
        end
      end
    end
  end
end
