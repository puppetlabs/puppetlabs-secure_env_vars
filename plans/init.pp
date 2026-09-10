# Run a command or script with sensitive environment variables.
# Environment variables are loaded from the BOLT_ENV_VARS environment
# variable, which is a JSON object mapping environment variable names
# to values.
# @param targets The targets to run the command or script on.
# @param command The command to run.
# @param script The script to run. This can be either a relative path, absolute path, or a file from a module.
plan secure_env_vars(
  TargetSpec       $targets,
  Optional[String] $command = undef,
  Optional[String] $script  = undef
) {
  unless type($command) == Undef or type($script) == Undef {
    fail_plan('Cannot specify both script and command for secure_env_vars')
  }

  $bolt_env_vars = system::env('BOLT_ENV_VARS')

  $env_vars = if $bolt_env_vars {
    parsejson($bolt_env_vars)
  }
  else {
    {}
  }

  return if $command {
    run_command($command, $targets, '_env_vars' => $env_vars)
  }
  elsif $script {
    run_script($script, $targets, '_env_vars' => $env_vars)
  }
  else {
    fail_plan('Must specify either script or command for secure_env_vars')
  }
}
