$: << File.expand_path(File.dirname(__FILE__))
# require 'isy/configuration'
require 'httparty'

class ISY
  # include Configuration
  include HTTParty
  default_options.update(verify: false)
  format :xml
  # debug_output $stdout

  def initialize (base_uri, user, pass)
    self.class.base_uri base_uri
    self.class.basic_auth user, pass
    # @var_definitions = []
  end

  def nodes()
    get_groups_nodes('nodes')
  end

  def groups()
    get_groups_nodes('groups')
  end

  def progs()
    # the drop(1) is a hack to remove the bogus "My Programs" header that shows up at the beginning of the list
    @progs ||= get('/rest/programs/')['programs']['program'].drop(1)
  end

  def node_on?(node_address)
    if node_level(node_address)
      node_level(node_address) > 0 ? true : false
    end
  end

  def node_on(node_address)
    get("/rest/nodes/#{encode(node_address)}/cmd/DON")
  end

  def node_off(node_address)
    get("/rest/nodes/#{encode(node_address)}/cmd/DOF")
  end

  def node_level(node_address)
    if get_node(node_address)
      get_node(node_address)['property']['value'].to_i
    end
  end

  def set_node_level(node_address, level)
    level = (level.to_i * 2.55).round(0) # convert percentage to integer in 0-255
    get("/rest/nodes/#{encode(node_address)}/cmd/DON/#{level}")
  end

  def find_var_by_name(name)
    get_int_var_defs.each do |var|
      return {'type' => 1 }.merge(var) if var.has_value?(name)
    end
    get_state_var_defs.each do |var|
      return {'type' => 2 }.merge(var) if var.has_value?(name)
    end
  end

  def value(type, var_id)
    convert_var_type(type)
    case type
    when 1
      get_int_vars
      @int_vars.each do |var|
        return var['val'] if var['id'] == var_id
      end
    when 2
      get_state_vars
      @state_vars.each do |var|
        return var['val'] if var['id'] == var_id
      end
    end
  end

  private

  def get(url)
    $stderr.puts "Getting URL: #{url} at #{Time.now}"
    rval = self.class.get(url)
    # $stderr.puts "Finished GET at #{Time.now}"
    # return rval
  end

  def get_groups_nodes(type)
    @groups_nodes ||= get('/rest/nodes/')['nodes']
    case type
    when 'nodes'
      @groups_nodes['node']
    when 'groups'
      @groups_nodes['group']
    else
      @groups_nodes
    end
  end

  def get_int_vars()
    @int_vars ||= get('/rest/vars/get/1/')['vars']['var']
  end

  def get_state_vars()
    @state_vars ||= get('/rest/vars/get/2/')['vars']['var']
  end

  def get_int_var_defs()
    @int_var_defs ||= get('/rest/vars/definitions/1/')['CList']['e']
  end

  def get_state_var_defs()
    @state_var_defs ||= get('/rest/vars/definitions/2/')['CList']['e']
  end

  def get_var_definitions(type = nil)
    if type
      @var_definitions[type-1] ||= get("/rest/vars/definitions/#{type}/")['CList']
    else
      [1,2].each do |type|
        @var_definitions[type-1] ||= get("/rest/vars/definitions/#{type}/")['CList']
      end
    end
    @var_definitions
  end

  def convert_var_type(type)
    case type
    when /int(eger)?/ || 1
      return 1
    when 'state' || 2
      return 2
    end
  end

  def get_node(node_address)
    nodes.each do |node|
      return node if node['address'] == node_address
    end
    return nil
  end

  def encode(node_address)
    URI::encode(node_address)
  end

  # TODO?
  # * error checking resonses
    # unless response.class == HTTParty::Response
    #   raise Alfred::NoBundleIDError, "Got unexpected response class \"#{response.class}\" from ISY!  Check your URL."
    # end
    # unless nodes.is_a? Array
    #   raise Alfred::NoBundleIDError, "Got wrong reply type from ISY!  Check your URL."
    # end
    # unless nodes[1].has_key? 'name' and nodes[1]["name"].is_a? String
    #   raise Alfred::NoBundleIDError, "ISY output is an unexpected type: #{nodes[1].class}"
    # end
  # * implement sorting


end