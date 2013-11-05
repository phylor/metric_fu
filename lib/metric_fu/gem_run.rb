# encoding: utf-8
require 'open3'
require 'shellwords'
require 'metric_fu'
MetricFu.lib_require { 'logging/mf_debugger' }
MetricFu.lib_require { 'gem_version' }
module MetricFu
  class GemRun

    attr_reader :output, :gem_name, :library_name, :version, :arguments
    def initialize(arguments={})
      @gem_name    = arguments.fetch(:gem_name)
      @library_name = arguments.fetch(:metric_name)
      @version = arguments.fetch(:version) { MetricFu::GemVersion.for(library_name) }
      args = arguments.fetch(:args)
      @arguments = args.respond_to?(:scan) ? Shellwords.shellwords(args) : args
      @output = ''
      @errors = []
    end

    def summary
      "RubyGem #{gem_name}, library #{library_name}, version #{version}, arguments #{arguments}"
    end

    def run
      @output = execute
    end

    def execute
      captured_output = ''
      Open3.popen3("#{library_name}", *arguments) do |stdin, stdout, stderr, wait_thr|
        captured_output << stdout.read.chomp
      end
    rescue StandardError => run_error
      handle_run_error(run_error)
    rescue SystemExit => system_exit
      handle_system_exit(system_exit)
    ensure
      print_errors
      return captured_output
    end

    def handle_run_error(run_error)
      @errors << "ERROR: #{run_error.inspect}"
    end

    def handle_system_exit(system_exit)
      status =  system_exit.success? ? "SUCCESS" : "FAILURE"
      @errors << "#{status} with code #{system_exit.status}: #{system_exit.inspect}"
    end

    def print_errors
      return unless defined?(@errors) and not @errors.empty?
      STDERR.puts @errors.map(&:inspect).join(", ")
    end

  end
end
