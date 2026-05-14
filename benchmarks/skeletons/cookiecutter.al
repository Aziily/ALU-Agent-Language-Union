flow cookiecutter_lib:
  steps:
    - cli_group
    - config_group
    - environment_group
    - extensions_group
    - find_group
    - generate_group
    - hooks_group
    - log_group
    - main_group
    - prompt_group
    - replay_group
    - repository_group
    - utils_group
    - vcs_group
    - zipfile_group


flow cli_group:
  steps:
    - version_msg
    - validate_extra_context
    - list_installed_templates
    - main


flow config_group:
  steps:
    - _expand_path
    - merge_configs
    - get_config
    - get_user_config


flow environment_group:
  steps:
    - ExtensionLoaderMixin___read_extensions


flow extensions_group:
  steps:
    - TimeExtension__parse


flow find_group:
  steps:
    - find_template


flow generate_group:
  steps:
    - is_copy_only_path
    - apply_overwrites_to_context
    - generate_context
    - generate_file
    - render_and_create_dir
    - _run_hook_from_repo_dir
    - generate_files


flow hooks_group:
  steps:
    - valid_hook
    - find_hook
    - run_script
    - run_script_with_context
    - run_hook
    - run_hook_from_repo_dir
    - run_pre_prompt_hook


flow log_group:
  steps:
    - configure_logger


flow main_group:
  steps:
    - cookiecutter


flow prompt_group:
  steps:
    - read_user_variable
    - YesNoPrompt__process_response
    - read_user_yes_no
    - read_repo_password
    - read_user_choice
    - process_json
    - JsonPrompt__process_response
    - read_user_dict
    - render_variable
    - _prompts_from_options
    - prompt_choice_for_template
    - prompt_choice_for_config
    - prompt_for_config
    - choose_nested_template
    - prompt_and_delete


flow replay_group:
  steps:
    - get_file_name
    - dump
    - load


flow repository_group:
  steps:
    - is_repo_url
    - is_zip_file
    - expand_abbreviations
    - repository_has_cookiecutter_json
    - determine_repo_dir


flow utils_group:
  steps:
    - force_delete
    - rmtree
    - make_sure_path_exists
    - work_in
    - make_executable
    - simple_filter
    - create_tmp_repo_dir
    - create_env_with_context


flow vcs_group:
  steps:
    - identify_repo
    - is_vcs_installed
    - clone


flow zipfile_group:
  steps:
    - unzip


code version_msg:
  body: |
    def version_msg():
        """Return the Cookiecutter version, location and Python powering it."""
        pass


code validate_extra_context:
  body: |
    def validate_extra_context(ctx, param, value):
        """Validate extra context."""
        pass


code list_installed_templates:
  body: |
    def list_installed_templates(default_config, passed_config_file):
        """List installed (locally cloned) templates. Use cookiecutter --list-installed."""
        pass


code main:
  body: |
    def main(template, extra_context, no_input, checkout, verbose, replay, overwrite_if_exists, output_dir, config_file, default_config, debug_file, directory, skip_if_file_exists, accept_hooks, replay_file, list_installed, keep_project_on_failure):
        """Create a project from a Cookiecutter project template (TEMPLATE).
    
        Cookiecutter is free and open source software, developed and managed by
        volunteers. If you would like to help out or fund the project, please get
        in touch at https://github.com/cookiecutter/cookiecutter.
        
        """
        pass


code _expand_path:
  body: |
    def _expand_path(path):
        """Expand both environment variables and user home in the given path."""
        pass


code merge_configs:
  body: |
    def merge_configs(default, overwrite):
        """Recursively update a dict with the key/value pair of another.
    
        Dict values that are dictionaries themselves will be updated, whilst
        preserving existing keys.
        
        """
        pass


code get_config:
  body: |
    def get_config(config_path):
        """Retrieve the config from the specified path, returning a config dict."""
        pass


code get_user_config:
  body: |
    def get_user_config(config_file=None, default_config=False):
        """Return the user config as a dict.
    
        If ``default_config`` is True, ignore ``config_file`` and return default
        values for the config parameters.
    
        If ``default_config`` is a dict, merge values with default values and return them
        for the config parameters.
    
        If a path to a ``config_file`` is given, that is different from the default
        location, load the user config from that.
    
        Otherwise look up the config file path in the ``COOKIECUTTER_CONFIG``
        environment variable. If set, load the config from this path. This will
        raise an error if the specified path is not valid.
    
        If the environment variable is not set, try the default config file path
        before falling back to the default config values.
        
        """
        pass


code ExtensionLoaderMixin___read_extensions:
  body: |
    def _read_extensions(self, context):
        """Return list of extensions as str to be passed on to the Jinja2 env.
    
            If context does not contain the relevant info, return an empty
            list instead.
            
        """
        pass


code TimeExtension__parse:
  body: |
    def parse(self, parser):
        """Parse datetime template and add datetime value."""
        pass


code find_template:
  body: |
    def find_template(repo_dir: 'os.PathLike[str]', env: Environment):
        """Determine which child directory of ``repo_dir`` is the project template.
    
        :param repo_dir: Local directory of newly cloned repo.
        :return: Relative path to project template.
        
        """
        pass


code is_copy_only_path:
  body: |
    def is_copy_only_path(path, context):
        """Check whether the given `path` should only be copied and not rendered.
    
        Returns True if `path` matches a pattern in the given `context` dict,
        otherwise False.
    
        :param path: A file-system path referring to a file or dir that
            should be rendered or just copied.
        :param context: cookiecutter context.
        
        """
        pass


code apply_overwrites_to_context:
  body: |
    def apply_overwrites_to_context(context, overwrite_context, *, in_dictionary_variable=False):
        """Modify the given context in place based on the overwrite_context."""
        pass


code generate_context:
  body: |
    def generate_context(context_file='cookiecutter.json', default_context=None, extra_context=None):
        """Generate the context for a Cookiecutter project template.
    
        Loads the JSON file as a Python object, with key being the JSON filename.
    
        :param context_file: JSON file containing key/value pairs for populating
            the cookiecutter's variables.
        :param default_context: Dictionary containing config to take into account.
        :param extra_context: Dictionary containing configuration overrides
        
        """
        pass


code generate_file:
  body: |
    def generate_file(project_dir, infile, context, env, skip_if_file_exists=False):
        """Render filename of infile as name of outfile, handle infile correctly.
    
        Dealing with infile appropriately:
    
            a. If infile is a binary file, copy it over without rendering.
            b. If infile is a text file, render its contents and write the
               rendered infile to outfile.
    
        Precondition:
    
            When calling `generate_file()`, the root template dir must be the
            current working directory. Using `utils.work_in()` is the recommended
            way to perform this directory change.
    
        :param project_dir: Absolute path to the resulting generated project.
        :param infile: Input file to generate the file from. Relative to the root
            template dir.
        :param context: Dict for populating the cookiecutter's variables.
        :param env: Jinja2 template execution environment.
        
        """
        pass


code render_and_create_dir:
  body: |
    def render_and_create_dir(dirname: str, context: dict, output_dir: 'os.PathLike[str]', environment: Environment, overwrite_if_exists: bool=False):
        """Render name of a directory, create the directory, return its path."""
        pass


code _run_hook_from_repo_dir:
  body: |
    def _run_hook_from_repo_dir(repo_dir, hook_name, project_dir, context, delete_project_on_failure):
        """Run hook from repo directory, clean project directory if hook fails.
    
        :param repo_dir: Project template input directory.
        :param hook_name: The hook to execute.
        :param project_dir: The directory to execute the script from.
        :param context: Cookiecutter project context.
        :param delete_project_on_failure: Delete the project directory on hook
            failure?
        
        """
        pass


code generate_files:
  body: |
    def generate_files(repo_dir, context=None, output_dir='.', overwrite_if_exists=False, skip_if_file_exists=False, accept_hooks=True, keep_project_on_failure=False):
        """Render the templates and saves them to files.
    
        :param repo_dir: Project template input directory.
        :param context: Dict for populating the template's variables.
        :param output_dir: Where to output the generated project dir into.
        :param overwrite_if_exists: Overwrite the contents of the output directory
            if it exists.
        :param skip_if_file_exists: Skip the files in the corresponding directories
            if they already exist
        :param accept_hooks: Accept pre and post hooks if set to `True`.
        :param keep_project_on_failure: If `True` keep generated project directory even when
            generation fails
        
        """
        pass


code valid_hook:
  body: |
    def valid_hook(hook_file, hook_name):
        """Determine if a hook file is valid.
    
        :param hook_file: The hook file to consider for validity
        :param hook_name: The hook to find
        :return: The hook file validity
        
        """
        pass


code find_hook:
  body: |
    def find_hook(hook_name, hooks_dir='hooks'):
        """Return a dict of all hook scripts provided.
    
        Must be called with the project template as the current working directory.
        Dict's key will be the hook/script's name, without extension, while values
        will be the absolute path to the script. Missing scripts will not be
        included in the returned dict.
    
        :param hook_name: The hook to find
        :param hooks_dir: The hook directory in the template
        :return: The absolute path to the hook script or None
        
        """
        pass


code run_script:
  body: |
    def run_script(script_path, cwd='.'):
        """Execute a script from a working directory.
    
        :param script_path: Absolute path to the script to run.
        :param cwd: The directory to run the script from.
        
        """
        pass


code run_script_with_context:
  body: |
    def run_script_with_context(script_path, cwd, context):
        """Execute a script after rendering it with Jinja.
    
        :param script_path: Absolute path to the script to run.
        :param cwd: The directory to run the script from.
        :param context: Cookiecutter project template context.
        
        """
        pass


code run_hook:
  body: |
    def run_hook(hook_name, project_dir, context):
        """
        Try to find and execute a hook from the specified project directory.
    
        :param hook_name: The hook to execute.
        :param project_dir: The directory to execute the script from.
        :param context: Cookiecutter project context.
        
        """
        pass


code run_hook_from_repo_dir:
  body: |
    def run_hook_from_repo_dir(repo_dir, hook_name, project_dir, context, delete_project_on_failure):
        """Run hook from repo directory, clean project directory if hook fails.
    
        :param repo_dir: Project template input directory.
        :param hook_name: The hook to execute.
        :param project_dir: The directory to execute the script from.
        :param context: Cookiecutter project context.
        :param delete_project_on_failure: Delete the project directory on hook
            failure?
        
        """
        pass


code run_pre_prompt_hook:
  body: |
    def run_pre_prompt_hook(repo_dir: 'os.PathLike[str]'):
        """Run pre_prompt hook from repo directory.
    
        :param repo_dir: Project template input directory.
        
        """
        pass


code configure_logger:
  body: |
    def configure_logger(stream_level='DEBUG', debug_file=None):
        """Configure logging for cookiecutter.
    
        Set up logging to stdout with given level. If ``debug_file`` is given set
        up logging to file with DEBUG level.
        
        """
        pass


code cookiecutter:
  body: |
    def cookiecutter(template, checkout=None, no_input=False, extra_context=None, replay=None, overwrite_if_exists=False, output_dir='.', config_file=None, default_config=False, password=None, directory=None, skip_if_file_exists=False, accept_hooks=True, keep_project_on_failure=False):
        """
        Run Cookiecutter just as if using it from the command line.
    
        :param template: A directory containing a project template directory,
            or a URL to a git repository.
        :param checkout: The branch, tag or commit ID to checkout after clone.
        :param no_input: Do not prompt for user input.
            Use default values for template parameters taken from `cookiecutter.json`, user
            config and `extra_dict`. Force a refresh of cached resources.
        :param extra_context: A dictionary of context that overrides default
            and user configuration.
        :param replay: Do not prompt for input, instead read from saved json. If
            ``True`` read from the ``replay_dir``.
            if it exists
        :param overwrite_if_exists: Overwrite the contents of the output directory
            if it exists.
        :param output_dir: Where to output the generated project dir into.
        :param config_file: User configuration file path.
        :param default_config: Use default values rather than a config file.
        :param password: The password to use when extracting the repository.
        :param directory: Relative path to a cookiecutter template in a repository.
        :param skip_if_file_exists: Skip the files in the corresponding directories
            if they already exist.
        :param accept_hooks: Accept pre and post hooks if set to `True`.
        :param keep_project_on_failure: If `True` keep generated project directory even when
            generation fails
        
        """
        pass


code read_user_variable:
  body: |
    def read_user_variable(var_name, default_value, prompts=None, prefix=''):
        """Prompt user for variable and return the entered value or given default.
    
        :param str var_name: Variable of the context to query the user
        :param default_value: Value that will be returned if no input happens
        
        """
        pass


code YesNoPrompt__process_response:
  body: |
    def process_response(self, value: str):
        """Convert choices to a bool."""
        pass


code read_user_yes_no:
  body: |
    def read_user_yes_no(var_name, default_value, prompts=None, prefix=''):
        """Prompt the user to reply with 'yes' or 'no' (or equivalent values).
    
        - These input values will be converted to ``True``:
          "1", "true", "t", "yes", "y", "on"
        - These input values will be converted to ``False``:
          "0", "false", "f", "no", "n", "off"
    
        Actual parsing done by :func:`prompt`; Check this function codebase change in
        case of unexpected behaviour.
    
        :param str question: Question to the user
        :param default_value: Value that will be returned if no input happens
        
        """
        pass


code read_repo_password:
  body: |
    def read_repo_password(question):
        """Prompt the user to enter a password.
    
        :param str question: Question to the user
        
        """
        pass


code read_user_choice:
  body: |
    def read_user_choice(var_name, options, prompts=None, prefix=''):
        """Prompt the user to choose from several options for the given variable.
    
        The first item will be returned if no input happens.
    
        :param str var_name: Variable as specified in the context
        :param list options: Sequence of options that are available to select from
        :return: Exactly one item of ``options`` that has been chosen by the user
        
        """
        pass


code process_json:
  body: |
    def process_json(user_value, default_value=None):
        """Load user-supplied value as a JSON dict.
    
        :param str user_value: User-supplied value to load as a JSON dict
        
        """
        pass


code JsonPrompt__process_response:
  body: |
    def process_response(self, value: str):
        """Convert choices to a dict."""
        pass


code read_user_dict:
  body: |
    def read_user_dict(var_name, default_value, prompts=None, prefix=''):
        """Prompt the user to provide a dictionary of data.
    
        :param str var_name: Variable as specified in the context
        :param default_value: Value that will be returned if no input is provided
        :return: A Python dictionary to use in the context.
        
        """
        pass


code render_variable:
  body: |
    def render_variable(env, raw, cookiecutter_dict):
        """Render the next variable to be displayed in the user prompt.
    
        Inside the prompting taken from the cookiecutter.json file, this renders
        the next variable. For example, if a project_name is "Peanut Butter
        Cookie", the repo_name could be be rendered with:
    
            `{{ cookiecutter.project_name.replace(" ", "_") }}`.
    
        This is then presented to the user as the default.
    
        :param Environment env: A Jinja2 Environment object.
        :param raw: The next value to be prompted for by the user.
        :param dict cookiecutter_dict: The current context as it's gradually
            being populated with variables.
        :return: The rendered value for the default variable.
        
        """
        pass


code _prompts_from_options:
  body: |
    def _prompts_from_options(options: dict):
        """Process template options and return friendly prompt information."""
        pass


code prompt_choice_for_template:
  body: |
    def prompt_choice_for_template(key, options, no_input):
        """Prompt user with a set of options to choose from.
    
        :param no_input: Do not prompt for user input and return the first available option.
        
        """
        pass


code prompt_choice_for_config:
  body: |
    def prompt_choice_for_config(cookiecutter_dict, env, key, options, no_input, prompts=None, prefix=''):
        """Prompt user with a set of options to choose from.
    
        :param no_input: Do not prompt for user input and return the first available option.
        
        """
        pass


code prompt_for_config:
  body: |
    def prompt_for_config(context, no_input=False):
        """Prompt user to enter a new config.
    
        :param dict context: Source for field names and sample values.
        :param no_input: Do not prompt for user input and use only values from context.
        
        """
        pass


code choose_nested_template:
  body: |
    def choose_nested_template(context: dict, repo_dir: str, no_input: bool=False):
        """Prompt user to select the nested template to use.
    
        :param context: Source for field names and sample values.
        :param repo_dir: Repository directory.
        :param no_input: Do not prompt for user input and use only values from context.
        :returns: Path to the selected template.
        
        """
        pass


code prompt_and_delete:
  body: |
    def prompt_and_delete(path, no_input=False):
        """
        Ask user if it's okay to delete the previously-downloaded file/directory.
    
        If yes, delete it. If no, checks to see if the old version should be
        reused. If yes, it's reused; otherwise, Cookiecutter exits.
    
        :param path: Previously downloaded zipfile.
        :param no_input: Suppress prompt to delete repo and just delete it.
        :return: True if the content was deleted
        
        """
        pass


code get_file_name:
  body: |
    def get_file_name(replay_dir, template_name):
        """Get the name of file."""
        pass


code dump:
  body: |
    def dump(replay_dir: 'os.PathLike[str]', template_name: str, context: dict):
        """Write json data to file."""
        pass


code load:
  body: |
    def load(replay_dir, template_name):
        """Read json data from file."""
        pass


code is_repo_url:
  body: |
    def is_repo_url(value):
        """Return True if value is a repository URL."""
        pass


code is_zip_file:
  body: |
    def is_zip_file(value):
        """Return True if value is a zip file."""
        pass


code expand_abbreviations:
  body: |
    def expand_abbreviations(template, abbreviations):
        """Expand abbreviations in a template name.
    
        :param template: The project template name.
        :param abbreviations: Abbreviation definitions.
        
        """
        pass


code repository_has_cookiecutter_json:
  body: |
    def repository_has_cookiecutter_json(repo_directory):
        """Determine if `repo_directory` contains a `cookiecutter.json` file.
    
        :param repo_directory: The candidate repository directory.
        :return: True if the `repo_directory` is valid, else False.
        
        """
        pass


code determine_repo_dir:
  body: |
    def determine_repo_dir(template, abbreviations, clone_to_dir, checkout, no_input, password=None, directory=None):
        """
        Locate the repository directory from a template reference.
    
        Applies repository abbreviations to the template reference.
        If the template refers to a repository URL, clone it.
        If the template is a path to a local repository, use it.
    
        :param template: A directory containing a project template directory,
            or a URL to a git repository.
        :param abbreviations: A dictionary of repository abbreviation
            definitions.
        :param clone_to_dir: The directory to clone the repository into.
        :param checkout: The branch, tag or commit ID to checkout after clone.
        :param no_input: Do not prompt for user input and eventually force a refresh of
            cached resources.
        :param password: The password to use when extracting the repository.
        :param directory: Directory within repo where cookiecutter.json lives.
        :return: A tuple containing the cookiecutter template directory, and
            a boolean describing whether that directory should be cleaned up
            after the template has been instantiated.
        :raises: `RepositoryNotFound` if a repository directory could not be found.
        
        """
        pass


code force_delete:
  body: |
    def force_delete(func, path, exc_info):
        """Error handler for `shutil.rmtree()` equivalent to `rm -rf`.
    
        Usage: `shutil.rmtree(path, onerror=force_delete)`
        From https://docs.python.org/3/library/shutil.html#rmtree-example
        
        """
        pass


code rmtree:
  body: |
    def rmtree(path):
        """Remove a directory and all its contents. Like rm -rf on Unix.
    
        :param path: A directory path.
        
        """
        pass


code make_sure_path_exists:
  body: |
    def make_sure_path_exists(path: 'os.PathLike[str]'):
        """Ensure that a directory exists.
    
        :param path: A directory tree path for creation.
        
        """
        pass


code work_in:
  body: |
    def work_in(dirname=None):
        """Context manager version of os.chdir.
    
        When exited, returns to the working directory prior to entering.
        
        """
        pass


code make_executable:
  body: |
    def make_executable(script_path):
        """Make `script_path` executable.
    
        :param script_path: The file to change
        
        """
        pass


code simple_filter:
  body: |
    def simple_filter(filter_function):
        """Decorate a function to wrap it in a simplified jinja2 extension."""
        pass


code create_tmp_repo_dir:
  body: |
    def create_tmp_repo_dir(repo_dir: 'os.PathLike[str]'):
        """Create a temporary dir with a copy of the contents of repo_dir."""
        pass


code create_env_with_context:
  body: |
    def create_env_with_context(context: Dict):
        """Create a jinja environment using the provided context."""
        pass


code identify_repo:
  body: |
    def identify_repo(repo_url):
        """Determine if `repo_url` should be treated as a URL to a git or hg repo.
    
        Repos can be identified by prepending "hg+" or "git+" to the repo URL.
    
        :param repo_url: Repo URL of unknown type.
        :returns: ('git', repo_url), ('hg', repo_url), or None.
        
        """
        pass


code is_vcs_installed:
  body: |
    def is_vcs_installed(repo_type):
        """
        Check if the version control system for a repo type is installed.
    
        :param repo_type:
        
        """
        pass


code clone:
  body: |
    def clone(repo_url: str, checkout: Optional[str]=None, clone_to_dir: 'os.PathLike[str]'='.', no_input: bool=False):
        """Clone a repo to the current directory.
    
        :param repo_url: Repo URL of unknown type.
        :param checkout: The branch, tag or commit ID to checkout after clone.
        :param clone_to_dir: The directory to clone to.
                             Defaults to the current directory.
        :param no_input: Do not prompt for user input and eventually force a refresh of
            cached resources.
        :returns: str with path to the new directory of the repository.
        
        """
        pass


code unzip:
  body: |
    def unzip(zip_uri: str, is_url: bool, clone_to_dir: 'os.PathLike[str]'='.', no_input: bool=False, password: Optional[str]=None):
        """Download and unpack a zipfile at a given URI.
    
        This will download the zipfile to the cookiecutter repository,
        and unpack into a temporary directory.
    
        :param zip_uri: The URI for the zipfile.
        :param is_url: Is the zip URI a URL or a file?
        :param clone_to_dir: The cookiecutter repository directory
            to put the archive into.
        :param no_input: Do not prompt for user input and eventually force a refresh of
            cached resources.
        :param password: The password to use when unpacking the repository.
        
        """
        pass
