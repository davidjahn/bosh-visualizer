require "json"
require "kemal"
require "io/memory"

require "./concourse-summary/*"

serve_static({"gzip" => true, "dir_listing" => false})
gzip true

REFRESH_INTERVAL = (ENV["REFRESH_INTERVAL"]? || 10).to_i
# GROUPS = parse_groups(ENV["CS_GROUPS"]? || "{}")

# def setup(env)
#   refresh_interval = REFRESH_INTERVAL
#   # username = env.store["credentials_username"]?.to_s
#   # password = env.store["credentials_password"]?.to_s
#   # team_name = "main"

#   # login_form = env.params.query.has_key?("login_form")
#   # if env.params.query.has_key?("login_team")
#   #   team_name = env.params.query["login_team"].to_s
#   #   login_form = true
#   # end
#   # if login_form && (username.size == 0 || password.size == 0)
#   #   raise Unauthorized.new
#   # end

#   # collapso_toggle = env.params.query.map {|k,_| k}
#   # ignore_groups = env.params.query.has_key?("ignore_groups")
#   # if ignore_groups
#   #   collapso_toggle = collapso_toggle - ["ignore_groups"]
#   # else
#   #   collapso_toggle = collapso_toggle + ["ignore_groups"]
#   # end

#   {refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name}
# end

def run_command(command, args)
  io = IO::Memory.new
  Process.run(command, args, output: io)
  io.to_s
end

class BoshVM
  def initialize(name : String, status : String)
    @name = name
    @status = status
  end
  def name
    @name
  end
  def status
    @status
  end
end

def get_vms
  command = "bosh"
  args = ["-d", "#{ENV["DEPLOYMENT_NAME"]}", "vms", "--json"]
  result = JSON.parse(run_command(command,args))

  vms = [] of BoshVM
  result["Tables"].first["Rows"].each { |vm| vms << BoshVM.new(vm["instance"].to_s,vm["process_state"].to_s)}
  return vms
end

def process(data, ignore_groups)
  if ignore_groups
    MyData.remove_group_info(data)
  end
  statuses = MyData.statuses(data)
end

# get bosh_vm_status do |env|
#   `bosh vms`
# end

# get "/host/jobs/:host/**" do |env|
#   refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)
#   host = env.params.url["host"]

#   data = MyData.get_data(host, username, password, nil, login_form)
#   jobs = data.map do |pipeline,job|
#     JobInfo.new(pipeline, job)
#   end.select do |info|
#     info.running || (!info.status.nil? && info.status != "succeeded" && !info.paused)
#   end.sort_by{|a| a.start_time || 0 }

#   json_or_html(jobs, "jobs")
# end

# get "/jobs/match/:keyword/:host/**" do |env|
#   refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)
#   keyword = env.params.url["keyword"]
#   host = env.params.url["host"]

#   data = MyData.get_data(host, username, password, nil, login_form, team_name)
#   jobs = data.map do |pipeline,job|
#     JobInfo.new(pipeline, job)
#   end.select do |info|
#     info.name.includes? keyword
#   end.sort_by{|a| a.start_time || 0 }

#   json_or_html(jobs, "jobs")
# end

# get "/host/:host/**" do |env|
#   refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)
#   host = env.params.url["host"]

#   data = MyData.get_data(host, username, password, nil, login_form, team_name)
#   statuses = process(data, ignore_groups)

#   json_or_html(statuses, "host")
# end

# get "/group/:key" do |env|
#   refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)

#   hosts = GROUPS[env.params.url["key"]]
#   hosts = hosts.map do |host, pipelines|
#     data = MyData.get_data(host, username, password, pipelines)
#     data = MyData.filter_groups(data, pipelines)
#     statuses = process(data, ignore_groups)
#     { host, statuses }
#   end

#   json_or_html(hosts, "group")
# end

get "/" do |env|
  refresh_interval = REFRESH_INTERVAL
  # hosts = (ENV["HOSTS"]? || "").split(/\s+/)
  # groups = GROUPS.keys

  command_output = get_vms
  # json_or_html(command_output, "index")
  render "views/index.ecr", "views/layout.ecr"
end

Kemal.config.add_handler ExposeUnauthorizedHandler.new
Kemal.run
