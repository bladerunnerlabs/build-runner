#!/usr/bin/python3
#
# Copyright (c) 2019 - BladeRunner Labs
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software")
# to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import sys
import getopt
import glob
import yaml
import tarfile
import re
from shutil import rmtree
from os import makedirs, symlink, remove, getcwd, chdir, walk
from os.path import basename, dirname, isfile, exists, join, expandvars

tarpack_dir_parent = '.'
tarpack_dir_name = '.tarpack'
archive_fname = 'pack.tgz'
del_tarpack_dir = True
files = []

def usage():
    print('\nUsage: tarpack.py [options...]\n')
    print('-d|--dir <root_dir> : YAML files work directory [default: .]')
    print('                      (valid for all consequent YAML files)')
    print('-y|--yaml <yaml_file> : tarpack YAML file name (multiple entries allowed;')
    print('                        relative to the latest work dir)')
    print('-T|--tag <tag_name> : tag to be matched against TAGS list, multiple values accepted')
    print('-o|--out <out_tgz> : tar.gz output file path [default: ./' + archive_fname + ']')
    print('-t|--tar-dir <tar_dir> : tar (symlinks only) source directory path [default: .]')
    print('-k|--keep : keep tar (symlinks only) source directory [default: remove]')
    print('-h|--help : print usage help message and exit')
    sys.exit()

def fatal_error(cfg_file, msg1, msg2=None, msg3=None, msg4=None, msg5=None):
    print()
    if cfg_file:
        print("ERROR: " + cfg_file)
    if msg1:
        print(msg1)
    if msg2:
        print(msg2)
    if msg3:
        print(msg3)
    if msg4:
        print(msg4)
    if msg5:
        print(msg5)
    sys.exit(1)


def concat_dest(path, dest):
    if dest[0] == '/':
        return dest
    else:
        return path + '/' + dest


def concat_tarpack(tarpack_dir, dest):
    if dest[0] == '/':
        return tarpack_dir + dest
    elif dest[0] == '.' and dest[1] != '.' :
        return concat_tarpack(tarpack_dir, dest[1:])
    else:
        return tarpack_dir + '/' + dest


def tar_print_name(tarinfo):
    if not tarinfo.isdir():
        print(tarinfo.name + " : " + str(tarinfo.size))
    return tarinfo


def lists_intersect(list1, list2):
    return [value for value in list1 if value in list2]


def select_tags(item_tags):
    if not isinstance(item_tags, list):
        item_tags = [ item_tags ]
    return lists_intersect(item_tags, tags_list)


def create_symlink(src_path, symlink_path, cfg_file, force=False):
    try:
        if not exists(src_path):
            fatal_error(cfg_file, "\nsymlink src file not found:", src_path)
        symlink(src_path, symlink_path)
    except FileExistsError as err:
        if force:
            print("\nsymlink (dst) already exists:\n" + str(err))
            print("\nconfig_file: " + cfg_file)
            print("REPLACE=True, Force create...\n")
            remove(symlink_path)
            create_symlink(src_path, symlink_path, cfg_file, force)
        else:
            fatal_error(cfg_file, str(err), "\nsymlink (dst) already exists, but REPLACE=False:", tarpack_dst_path)
    except PermissionError:
        fatal_error(cfg_file, str(err), "\npermission denied:", tarpack_dst_path)
    except FileNotFoundError:
        fatal_error(cfg_file, str(err), "\nsymlink src file not found:", src_path)


def read_yaml(yaml_path):
    if not exists(yaml_path):
       fatal_error(yaml_path, "YAML file not found")

    pattern = re.compile(r'.*\$\{([^}^{]+)\}.*')

    def env_constructor(loader, node):
        return expandvars(node.value)

    class EnvVarLoader(yaml.SafeLoader):
        pass

    EnvVarLoader.add_implicit_resolver('!env', pattern, None)
    EnvVarLoader.add_constructor('!env', env_constructor)

    with open(yaml_path, 'r') as yaml_stream:
        try:
            return yaml.load(yaml_stream, Loader=EnvVarLoader)
        except yaml.YAMLError as exc:
            print(exc)


def handle_pack_list(cfg_file, pack_list, path, dest=None):
    for item in pack_list:
        handle_pack_item(cfg_file, item, path, dest)


def handle_pack_item(cfg_file, item, path, dest):
    if 'INCLUDE' in item:
        handle_include_item(cfg_file, item, path, dest)
    elif 'DIR' in item:
        handle_dir_item(cfg_file, item, path, dest)
    elif 'TREE' in item:
        handle_tree_item(cfg_file, item, path, dest)
    elif 'FILES' in item:
        handle_files_item(cfg_file, item, path, dest)
    else:
        fatal_error(cfg_file, "Unsupported PACK list item type", item)


def verify_implied_dir_item(cfg_file, yaml):
    if isinstance(yaml, list):
        fatal_error(cfg_file, "list detected; a single DIR item content is implied",
                    "list items can be added to the PACK list")

    if 'DIR' in yaml:
        fatal_error(cfg_file, "explicit DIR item; implied DIR item content",
                    "DIR items can be added to the PACK list")

    if 'PACK' not in yaml:
        fatal_error(cfg_file, "PACK list missing")


def handle_include_item(cfg_file, item, path, dest):
    include_file = concat_dest(path, item['INCLUDE'])
    include_dir = dirname(include_file)

    if 'TAGS' in item:
        selected_tags = select_tags(item['TAGS'])
        if selected_tags:
            print(cfg_file + " INCLUDE: " + include_file + ", selected tags " + str(selected_tags))
        else:
            print(cfg_file + " INCLUDE: " + include_file + ", skipped tags " + str(item['TAGS']))
            return

    include_yaml = read_yaml(include_file)
    verify_implied_dir_item(cfg_file, include_yaml)

    print(cfg_file + ": INCLUDE " + include_file + " DEST " + dest)
    handle_dir_item(include_file, include_yaml, include_dir, dest)


def handle_files_item(cfg_file, item, path, dest):
    if 'DEST' in item:
        item['DEST'] = concat_dest(dest, item['DEST'])
    else:
        item['DEST'] = dest

    if not item['DEST']:
        fatal_error(cfg_file, "DEST unresolved", item)

    if 'TAGS' in item:
        selected_tags = select_tags(item['TAGS'])
        if selected_tags:
            print(cfg_file + " FILES: selected tags " + str(selected_tags))
        else:
            print(cfg_file + " FILES: skipped tags " + str(item['TAGS']))
            return

    handle_files_list(cfg_file, item['FILES'], path, item['DEST'])


def handle_dir_item(cfg_file, item, path, dest):
    if isinstance(item, list):
        fatal_error(cfg_file, "DIR item is a list",
                    "list items can be added to the PACK list")

    if 'PACK' not in item:
        fatal_error(cfg_file, ": PACK list missing")

    if 'TAGS' in item:
        selected_tags = select_tags(item['TAGS'])
        if selected_tags:
            print(cfg_file + " DIR: selected tags " + str(selected_tags))
        else:
            print(cfg_file + " DIR: skipped tags " + str(item['TAGS']))
            return

    if dest:
        if 'DEST' in item:
            item['DEST'] = concat_dest(dest, item['DEST'])
        else:
            item['DEST'] = dest
    elif 'DEST' not in item:
        fatal_error(cfg_file, ": DEST missing")

    if 'DIR' in item:
        if path:
            item['DIR'] = concat_dest(path, item['DIR'])
    else:
        item['DIR'] = path

    handle_pack_list(cfg_file, item['PACK'], item['DIR'], item['DEST'])


def handle_tree_item(cfg_file, item, path, dest):
    if 'TAGS' in item:
        selected_tags = select_tags(item['TAGS'])
        if selected_tags:
            print(cfg_file + " TREE " + item['TREE'] + ": selected tags " + str(selected_tags))
        else:
            print(cfg_file + " TREE " + item['TREE'] + ": skipped tags " + str(item['TAGS']))
            return

    if 'DEST' in item:
        item['DEST'] = concat_dest(dest, item['DEST'])
    else:
        item['DEST'] = dest

    item['DIR'] = concat_dest(path, item['TREE'])

    if 'FILES' not in item:
        item['FILES'] = '*'

    if 'FLAT' in item:
        if isinstance(item['FLAT'], bool):
            dst_flat = item['FLAT']
        else:
            fatal_error(cfg_file, "TREE " + item['TREE'] + " contains non-boolean FLAT: " + item['FLAT'])
    else:
        dst_flat = False

    if isinstance(item['FILES'], list):
        for filter in item['FILES']:
            handle_tree_filter(cfg_file, item['DIR'], item['DEST'], filter, dst_flat)
    else:
        handle_tree_filter(cfg_file, item['DIR'], item['DEST'], item['FILES'], dst_flat)


def handle_files_list(cfg_file, files_list, path, dest):
    if isinstance(files_list, list):
        for file_name in files_list:
            handle_file(cfg_file, file_name, path, dest)
    else:
        handle_file(cfg_file, files_list, path, dest)


def handle_file(cfg_file, file_name, path, dest):
    if file_name == 'ALL':
        file_name = '*'

    path_spec = concat_dest(path, file_name)
    if '*' in file_name:
        expand_list = list_files(path_spec)
        handle_files_list(cfg_file, expand_list, path, dest)
    elif (file_name != 'NONE') and (path_spec != cfg_file):
        print(cfg_file + ": SRC " + path + " DEST " + dest + " FILE " + file_name)
        files.append({
            'src': path,
            'dest': dest,
            'name': file_name,
            'cfg': cfg_file
        })


def unique_suffix(a, b):
    return b[([x[0] == x[1] for x in zip(a, b)] + [0]).index(0) + 1:]


def handle_tree_filter(cfg_file, root_path, dest, filter, dst_flat):
    print(cfg_file + ": TREE " + root_path + " DEST " + dest + (" FLAT" if dst_flat else " PRESERVE") + " FILES " + filter)

    if filter == 'ALL':
        filter = '*'

    if dirname(filter) != '':
        fatal_error(cfg_file, "TREE " + root_path + ", FILES filter '" + filter + "' contains a path",
                    "TREE FILE filters may be only file names, full or regular expressions")

    expand_list = list_files(join(root_path, filter))
    handle_files_list(cfg_file, expand_list, root_path, dest)

    for root, subdirs, filenames in walk(root_path):
        for d in subdirs:
            d_path = join(root, d)
            expand_list = list_files(join(d_path, filter))
            if dst_flat:
                d_dest = dest
            else:
                suffix = unique_suffix(root_path, d_path)
                d_dest = join(dest, suffix)
            handle_files_list(cfg_file, expand_list, d_path, d_dest)


def list_files(path):
    try:
        return [basename(f) for f in glob.glob(path) if isfile(f)]
    except:
        return []


def handle_yaml(yaml_dir, yaml_name):
    yaml_path = yaml_dir + '/' + yaml_name
    base_yaml = read_yaml(yaml_path)
    verify_implied_dir_item(yaml_path, base_yaml)
    print("\n" + yaml_path + ": ROOT")
    handle_dir_item(yaml_path, base_yaml, yaml_dir, None)


def main(argv):
    global tarpack_dir_parent
    global tarpack_dir_name
    global archive_fname
    global del_tarpack_dir
    global files
    global tags_list

    cwd = getcwd()
    work_dir = cwd

    try:
        opts, args_left = getopt.getopt(argv,
                            "d:y:o:t:T:kh",
                            ["dir=","yaml=","out=","tar-dir=","tag=","keep","help"])
    except getopt.GetoptError as getopt_exc:
        fatal_error("options", getopt_exc.opt, getopt_exc.msg);

    if args_left:
        fatal_error("options", 'unrecognized: ', args_left)

    yaml_files = []
    tags_list = []

    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt in ('-k', '--keep'):
            del_tarpack_dir = False
            print('keep tarpack symlink dir\n')
        elif opt in ('-d', '--dir'):
            work_dir = arg
            if not exists(work_dir):
                fatal_error('-d|--dir', work_dir, 'directory does not exist')
            print("Set working dir: " + work_dir)
        elif opt in ('-y', '--yaml'):
            yf = work_dir + '/' + arg
            if not exists(yf):
                fatal_error("YAML", "file does not exist: ", yf)
            yaml_files.append({
                'dir': work_dir,
                'name': arg
            })
            print('added YAML file: ', yf)
        elif opt in ('-o', '--out'):
            archive_fname = arg
            print('output tar file path: ', archive_fname)
        elif opt in ('-t', '--tar-dir'):
            tarpack_dir_parent = arg
            if not exists(tarpack_dir_parent):
                fatal_error('-t|--tar-dir', tarpack_dir_parent, 'directory does not exist')
            print('tarpack symfile parent dir: ', tarpack_dir_parent)
        elif opt in ('-T', '--tag'):
            tags_list.append(arg)
        else:
            fatal_error('options', "unsupported: ", opt)

    # parse yaml config and create run-time config
    for yf in yaml_files:
        handle_yaml(yf['dir'], yf['name'])

    # re-create the packing dir
    tarpack_dir_path = tarpack_dir_parent + '/' + tarpack_dir_name
    rmtree(tarpack_dir_path, ignore_errors=True)
    makedirs(tarpack_dir_path, exist_ok=True)

    # create symlinks to the packed files
    print("\nCreating symlinks in: " + tarpack_dir_path + " ...\n");
    for file in files:
        file_name = file['name']
        src_dir = file['src']
        dst_dir = file['dest']

        # src path must be full, referenced from the tarpack symlinks dir
        src_path = concat_dest(cwd, src_dir + '/' + file_name)
        # dst path should be relative to the tarpack symlinks dir
        dst_path = dst_dir + '/' + file_name
        print(src_path + ' --> ' + dst_path)

        makedirs(tarpack_dir_path + '/' + dst_dir, exist_ok=True)
        tarpack_dst_path = concat_tarpack(tarpack_dir_path, dst_path)
        create_symlink(src_path, tarpack_dst_path, file['cfg'], True)

    # create archive
    print("\nCreating archive file: " + tarpack_dir_path + " --> " + archive_fname + " ... ");
    archive = tarfile.open(archive_fname, "w:gz", dereference=True)
    chdir(tarpack_dir_path)
    archive.add('.', filter=tar_print_name)
    archive.close()

    if del_tarpack_dir:
        print('\nRemove symlink dir: ' + tarpack_dir_path)
        rmtree(tarpack_dir_path, ignore_errors=True)
    else:
        print('\nKeep symlink dir: ' + tarpack_dir_path)

    print("Done\n")

if __name__ == "__main__":
   main(sys.argv[1:])
