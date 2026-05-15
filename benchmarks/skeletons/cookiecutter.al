preamble __init__:
  source: cookiecutter/__init__.py
  imports: |
    from pathlib import Path
  constants: |
    __version__ = _get_version()
  body: |
    'Main package for Cookiecutter.'


preamble __main__:
  source: cookiecutter/__main__.py
  imports: |
    from cookiecutter.cli import main
  body: |
    'Allow cookiecutter to be executable through `python -m cookiecutter`.'
    if __name__ == '__main__':
        main(prog_name='cookiecutter')


preamble cli:
  source: cookiecutter/cli.py
  imports: |
    import collections
    import json
    import os
    import sys
    import click
    from cookiecutter import __version__
    from cookiecutter.config import get_user_config
    from cookiecutter.exceptions import ContextDecodingException, FailedHookException, InvalidModeException, InvalidZipRepository, OutputDirExistsException, RepositoryCloneFailed, RepositoryNotFound, UndefinedVariableInTemplate, UnknownExtension
    from cookiecutter.log import configure_logger
    from cookiecutter.main import cookiecutter
  body: |
    'Main `cookiecutter` CLI.'
    if __name__ == '__main__':
        main()


preamble config:
  source: cookiecutter/config.py
  imports: |
    import collections
    import copy
    import logging
    import os
    import yaml
    from cookiecutter.exceptions import ConfigDoesNotExistException, InvalidConfiguration
  constants: |
    logger = logging.getLogger(__name__)
    USER_CONFIG_PATH = os.path.expanduser('~/.cookiecutterrc')
    BUILTIN_ABBREVIATIONS = {'gh': 'https://github.com/{0}.git', 'gl': 'https://gitlab.com/{0}.git', 'bb': 'https://bitbucket.org/{0}'}
    DEFAULT_CONFIG = {'cookiecutters_dir': os.path.expanduser('~/.cookiecutters/'), 'replay_dir': os.path.expanduser('~/.cookiecutter_replay/'), 'default_context': collections.OrderedDict([]), 'abbreviations': BUILTIN_ABBREVIATIONS}
  body: |
    'Global configuration handling.'


preamble environment:
  source: cookiecutter/environment.py
  imports: |
    from jinja2 import Environment, StrictUndefined
    from cookiecutter.exceptions import UnknownExtension
  body: |
    'Jinja2 environment and extensions loading.'
    class ExtensionLoaderMixin:
        """Mixin providing sane loading of extensions specified in a given context.

        The context is being extracted from the keyword arguments before calling
        the next parent class in line of the child.
        """

        def __init__(self, **kwargs):
            """Initialize the Jinja2 Environment object while loading extensions.

            Does the following:

            1. Establishes default_extensions (currently just a Time feature)
            2. Reads extensions set in the cookiecutter.json _extensions key.
            3. Attempts to load the extensions. Provides useful error if fails.
            """
            context = kwargs.pop('context', {})
            default_extensions = ['cookiecutter.extensions.JsonifyExtension', 'cookiecutter.extensions.RandomStringExtension', 'cookiecutter.extensions.SlugifyExtension', 'cookiecutter.extensions.TimeExtension', 'cookiecutter.extensions.UUIDExtension']
            extensions = default_extensions + self._read_extensions(context)
            try:
                super().__init__(extensions=extensions, **kwargs)
            except ImportError as err:
                raise UnknownExtension(f'Unable to load extension: {err}') from err

        def _read_extensions(self, context):
            """Return list of extensions as str to be passed on to the Jinja2 env.

            If context does not contain the relevant info, return an empty
            list instead.
            """
            pass
    class StrictEnvironment(ExtensionLoaderMixin, Environment):
        """Create strict Jinja2 environment.

        Jinja2 environment will raise error on undefined variable in template-
        rendering context.
        """

        def __init__(self, **kwargs):
            """Set the standard Cookiecutter StrictEnvironment.

            Also loading extensions defined in cookiecutter.json's _extensions key.
            """
            super().__init__(undefined=StrictUndefined, **kwargs)


preamble exceptions:
  source: cookiecutter/exceptions.py
  body: |
    'All exceptions used in the Cookiecutter code base are defined here.'
    class CookiecutterException(Exception):
        """
        Base exception class.

        All Cookiecutter-specific exceptions should subclass this class.
        """
    class NonTemplatedInputDirException(CookiecutterException):
        """
        Exception for when a project's input dir is not templated.

        The name of the input directory should always contain a string that is
        rendered to something else, so that input_dir != output_dir.
        """
    class UnknownTemplateDirException(CookiecutterException):
        """
        Exception for ambiguous project template directory.

        Raised when Cookiecutter cannot determine which directory is the project
        template, e.g. more than one dir appears to be a template dir.
        """
    class MissingProjectDir(CookiecutterException):
        """
        Exception for missing generated project directory.

        Raised during cleanup when remove_repo() can't find a generated project
        directory inside of a repo.
        """
    class ConfigDoesNotExistException(CookiecutterException):
        """
        Exception for missing config file.

        Raised when get_config() is passed a path to a config file, but no file
        is found at that path.
        """
    class InvalidConfiguration(CookiecutterException):
        """
        Exception for invalid configuration file.

        Raised if the global configuration file is not valid YAML or is
        badly constructed.
        """
    class UnknownRepoType(CookiecutterException):
        """
        Exception for unknown repo types.

        Raised if a repo's type cannot be determined.
        """
    class VCSNotInstalled(CookiecutterException):
        """
        Exception when version control is unavailable.

        Raised if the version control system (git or hg) is not installed.
        """
    class ContextDecodingException(CookiecutterException):
        """
        Exception for failed JSON decoding.

        Raised when a project's JSON context file can not be decoded.
        """
    class OutputDirExistsException(CookiecutterException):
        """
        Exception for existing output directory.

        Raised when the output directory of the project exists already.
        """
    class InvalidModeException(CookiecutterException):
        """
        Exception for incompatible modes.

        Raised when cookiecutter is called with both `no_input==True` and
        `replay==True` at the same time.
        """
    class FailedHookException(CookiecutterException):
        """
        Exception for hook failures.

        Raised when a hook script fails.
        """
    class UndefinedVariableInTemplate(CookiecutterException):
        """
        Exception for out-of-scope variables.

        Raised when a template uses a variable which is not defined in the
        context.
        """

        def __init__(self, message, error, context):
            """Exception for out-of-scope variables."""
            self.message = message
            self.error = error
            self.context = context

        def __str__(self):
            """Text representation of UndefinedVariableInTemplate."""
            return f'{self.message}. Error message: {self.error.message}. Context: {self.context}'
    class UnknownExtension(CookiecutterException):
        """
        Exception for un-importable extension.

        Raised when an environment is unable to import a required extension.
        """
    class RepositoryNotFound(CookiecutterException):
        """
        Exception for missing repo.

        Raised when the specified cookiecutter repository doesn't exist.
        """
    class RepositoryCloneFailed(CookiecutterException):
        """
        Exception for un-cloneable repo.

        Raised when a cookiecutter template can't be cloned.
        """
    class InvalidZipRepository(CookiecutterException):
        """
        Exception for bad zip repo.

        Raised when the specified cookiecutter repository isn't a valid
        Zip archive.
        """


preamble extensions:
  source: cookiecutter/extensions.py
  imports: |
    import json
    import string
    import uuid
    from secrets import choice
    import arrow
    from jinja2 import nodes
    from jinja2.ext import Extension
    from slugify import slugify as pyslugify
  body: |
    'Jinja2 extensions.'
    class JsonifyExtension(Extension):
        """Jinja2 extension to convert a Python object to JSON."""

        def __init__(self, environment):
            """Initialize the extension with the given environment."""
            super().__init__(environment)

            def jsonify(obj):
                return json.dumps(obj, sort_keys=True, indent=4)
            environment.filters['jsonify'] = jsonify
    class RandomStringExtension(Extension):
        """Jinja2 extension to create a random string."""

        def __init__(self, environment):
            """Jinja2 Extension Constructor."""
            super().__init__(environment)

            def random_ascii_string(length, punctuation=False):
                if punctuation:
                    corpus = ''.join((string.ascii_letters, string.punctuation))
                else:
                    corpus = string.ascii_letters
                return ''.join((choice(corpus) for _ in range(length)))
            environment.globals.update(random_ascii_string=random_ascii_string)
    class SlugifyExtension(Extension):
        """Jinja2 Extension to slugify string."""

        def __init__(self, environment):
            """Jinja2 Extension constructor."""
            super().__init__(environment)

            def slugify(value, **kwargs):
                """Slugifies the value."""
                return pyslugify(value, **kwargs)
            environment.filters['slugify'] = slugify
    class UUIDExtension(Extension):
        """Jinja2 Extension to generate uuid4 string."""

        def __init__(self, environment):
            """Jinja2 Extension constructor."""
            super().__init__(environment)

            def uuid4():
                """Generate UUID4."""
                return str(uuid.uuid4())
            environment.globals.update(uuid4=uuid4)
    class TimeExtension(Extension):
        """Jinja2 Extension for dates and times."""
        tags = {'now'}

        def __init__(self, environment):
            """Jinja2 Extension constructor."""
            super().__init__(environment)
            environment.extend(datetime_format='%Y-%m-%d')

        def parse(self, parser):
            """Parse datetime template and add datetime value."""
            pass


preamble find:
  source: cookiecutter/find.py
  imports: |
    import logging
    import os
    from pathlib import Path
    from jinja2 import Environment
    from cookiecutter.exceptions import NonTemplatedInputDirException
  constants: |
    logger = logging.getLogger(__name__)
  body: |
    'Functions for finding Cookiecutter templates and other components.'


preamble generate:
  source: cookiecutter/generate.py
  imports: |
    import fnmatch
    import json
    import logging
    import os
    import shutil
    import warnings
    from collections import OrderedDict
    from pathlib import Path
    from binaryornot.check import is_binary
    from jinja2 import Environment, FileSystemLoader
    from jinja2.exceptions import TemplateSyntaxError, UndefinedError
    from cookiecutter.exceptions import ContextDecodingException, OutputDirExistsException, UndefinedVariableInTemplate
    from cookiecutter.find import find_template
    from cookiecutter.hooks import run_hook_from_repo_dir
    from cookiecutter.utils import create_env_with_context, make_sure_path_exists, rmtree, work_in
  constants: |
    logger = logging.getLogger(__name__)
  body: |
    'Functions for generating a project from a project template.'


preamble hooks:
  source: cookiecutter/hooks.py
  imports: |
    import errno
    import logging
    import os
    import subprocess
    import sys
    import tempfile
    from pathlib import Path
    from jinja2.exceptions import UndefinedError
    from cookiecutter import utils
    from cookiecutter.exceptions import FailedHookException
    from cookiecutter.utils import create_env_with_context, create_tmp_repo_dir, rmtree, work_in
  constants: |
    logger = logging.getLogger(__name__)
    _HOOKS = ['pre_prompt', 'pre_gen_project', 'post_gen_project']
    EXIT_SUCCESS = 0
  body: |
    'Functions for discovering and executing various cookiecutter hooks.'


preamble log:
  source: cookiecutter/log.py
  imports: |
    import logging
    import sys
  constants: |
    LOG_LEVELS = {'DEBUG': logging.DEBUG, 'INFO': logging.INFO, 'WARNING': logging.WARNING, 'ERROR': logging.ERROR, 'CRITICAL': logging.CRITICAL}
    LOG_FORMATS = {'DEBUG': '%(levelname)s %(name)s: %(message)s', 'INFO': '%(levelname)s: %(message)s'}
  body: |
    'Module for setting up logging.'


preamble main:
  source: cookiecutter/main.py
  imports: |
    import logging
    import os
    import sys
    from copy import copy
    from pathlib import Path
    from cookiecutter.config import get_user_config
    from cookiecutter.exceptions import InvalidModeException
    from cookiecutter.generate import generate_context, generate_files
    from cookiecutter.hooks import run_pre_prompt_hook
    from cookiecutter.prompt import choose_nested_template, prompt_for_config
    from cookiecutter.replay import dump, load
    from cookiecutter.repository import determine_repo_dir
    from cookiecutter.utils import rmtree
  constants: |
    logger = logging.getLogger(__name__)
  body: |
    '\nMain entry point for the `cookiecutter` command.\n\nThe code in this module is also a good example of how to use Cookiecutter as a\nlibrary rather than a script.\n'
    class _patch_import_path_for_repo:

        def __init__(self, repo_dir: 'os.PathLike[str]'):
            self._repo_dir = f'{repo_dir}' if isinstance(repo_dir, Path) else repo_dir
            self._path = None

        def __enter__(self):
            self._path = copy(sys.path)
            sys.path.append(self._repo_dir)

        def __exit__(self, type, value, traceback):
            sys.path = self._path


preamble prompt:
  source: cookiecutter/prompt.py
  imports: |
    import json
    import os
    import re
    import sys
    from collections import OrderedDict
    from pathlib import Path
    from jinja2.exceptions import UndefinedError
    from rich.prompt import Confirm, InvalidResponse, Prompt, PromptBase
    from cookiecutter.exceptions import UndefinedVariableInTemplate
    from cookiecutter.utils import create_env_with_context, rmtree
  constants: |
    DEFAULT_DISPLAY = 'default'
  body: |
    'Functions for prompting the user for project info.'
    class YesNoPrompt(Confirm):
        """A prompt that returns a boolean for yes/no questions."""
        yes_choices = ['1', 'true', 't', 'yes', 'y', 'on']
        no_choices = ['0', 'false', 'f', 'no', 'n', 'off']

        def process_response(self, value: str) -> bool:
            """Convert choices to a bool."""
            pass
    class JsonPrompt(PromptBase[dict]):
        """A prompt that returns a dict from JSON string."""
        default = None
        response_type = dict
        validate_error_message = '[prompt.invalid]  Please enter a valid JSON string'

        def process_response(self, value: str) -> dict:
            """Convert choices to a dict."""
            pass


preamble replay:
  source: cookiecutter/replay.py
  imports: |
    import json
    import os
    from cookiecutter.utils import make_sure_path_exists
  body: |
    '\ncookiecutter.replay.\n\n-------------------\n'


preamble repository:
  source: cookiecutter/repository.py
  imports: |
    import os
    import re
    from cookiecutter.exceptions import RepositoryNotFound
    from cookiecutter.vcs import clone
    from cookiecutter.zipfile import unzip
  constants: |
    REPO_REGEX = re.compile('\n# something like git:// ssh:// file:// etc.\n((((git|hg)\\+)?(git|ssh|file|https?):(//)?)\n |                                      # or\n (\\w+@[\\w\\.]+)                          # something like user@...\n)\n', re.VERBOSE)
  body: |
    'Cookiecutter repository functions.'


preamble utils:
  source: cookiecutter/utils.py
  imports: |
    import contextlib
    import logging
    import os
    import shutil
    import stat
    import tempfile
    from pathlib import Path
    from typing import Dict
    from jinja2.ext import Extension
    from cookiecutter.environment import StrictEnvironment
  constants: |
    logger = logging.getLogger(__name__)
  body: |
    'Helper functions used throughout Cookiecutter.'


preamble vcs:
  source: cookiecutter/vcs.py
  imports: |
    import logging
    import os
    import subprocess
    from pathlib import Path
    from shutil import which
    from typing import Optional
    from cookiecutter.exceptions import RepositoryCloneFailed, RepositoryNotFound, UnknownRepoType, VCSNotInstalled
    from cookiecutter.prompt import prompt_and_delete
    from cookiecutter.utils import make_sure_path_exists
  constants: |
    logger = logging.getLogger(__name__)
    BRANCH_ERRORS = ['error: pathspec', 'unknown revision']
  body: |
    'Helper functions for working with version control systems.'


preamble zipfile:
  source: cookiecutter/zipfile.py
  imports: |
    import os
    import tempfile
    from pathlib import Path
    from typing import Optional
    from zipfile import BadZipFile, ZipFile
    import requests
    from cookiecutter.exceptions import InvalidZipRepository
    from cookiecutter.prompt import prompt_and_delete, read_repo_password
    from cookiecutter.utils import make_sure_path_exists
  body: |
    'Utility functions for handling and fetching repo archives in zip format.'


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
