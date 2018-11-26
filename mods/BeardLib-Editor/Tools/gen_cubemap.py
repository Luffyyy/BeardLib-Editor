"""
Receives 6 .tga filenames, cubemap type and the output name as input.
Looks in the temp folder to find the cube faces, blurs them, assembles cubemaps into one,
then converts them based on the type.

Input example: C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\BeardLib-Editor\Tools\gen_cubemap.py" reflect -i cubemap_gizmo_001_1_xneg.tga cubemap_gizmo_001_2_xpos.tga cubemap_gizmo_001_3_yneg.tga cubemap_gizmo_001_4_ypos.tga cubemap_gizmo_001_5_zneg.tga cubemap_gizmo_001_6_zpos.tga -o 100246.dds
"""
from os import path, remove, rename, getcwd
import sys
import logging
import subprocess
import argparse

import_status = False
try:
    from PIL import Image, ImageFilter
except ImportError:
    print("Pillow module not found! Cubemaps won't be blurred.\n")
else:
    import_status = True

__location__ = path.realpath(
    path.join(getcwd(), path.dirname(__file__)))

dir_path = (path.abspath(path.dirname(__file__)))
texass_path = path.join(__location__, "texassemble.exe")
texconv_path = path.join(__location__, "texconv.exe")

temp = "temp"


def get_args():
    parser = argparse.ArgumentParser(
        description='Assembles cube faces into a cubemap with a .texture format')
    parser.add_argument("type",
                        help="first arg has to be reflect, lights or dome_occ",
                        choices=["reflect", "light", "dome_occ"])
    parser.add_argument(
        "-i", help="input 6 filenames for each cube face or a single file for dome_occlusion", nargs="+")
    parser.add_argument("-o", help="output filename")

    args = parser.parse_args(sys.argv[1:])

    if not args.type:
        logging.error("[ERROR] Incorrect argument specified")
        sys.exit(1)

    return args.type, args.i, args.o

# can't specify output with texconv so I have to move the output
# from the rootdir to the temp folder


def move_and_rename_cubemap(cubemap_name):
    cubemap_path = path.abspath("") + "\\"
    # lazy way to remove .tga
    cubemap_name_new = cubemap_name[:-4] + ".texture"

    if not path.isfile(path.join(__location__, temp, cubemap_name_new)):
        rename(cubemap_path + cubemap_name,
               path.join(__location__, temp, cubemap_name_new))
    # remove old cubemap name
    if path.isfile(path.join(__location__, temp, cubemap_name)):
        remove(path.join(__location__, temp, cubemap_name))
    sys.exit(0)

# this script is called from lua by execute() with an absolute path,
# meaning that I have to make every filename have an absolute path too


def fix_paths(output_arg):
    if output_arg:
        output_paths = ["-o", path.join(__location__, temp, output_arg)]
    return output_paths


def start_process(proc_path, input):
    input.insert(0, proc_path)
    proc = subprocess.Popen(input, stdout=subprocess.PIPE)

    output, _ = proc.communicate()
    output = output.decode("utf-8", "ignore")

    print(output)
    logging.info(output)

    if str.find(output, "ERROR") != -1 or str.find(output, "Failed") != -1:
        logging.error(proc_path + " finished with an error!")
        sys.exit(1)


def convert_cubemaps(output_path, argtype):
    if argtype == "reflect":
        args = ["-m", "10", "-f", "BC2_UNORM", "-y"]
    elif argtype == "light":
        args = ["-m", "8", "-f", "BC3_UNORM", "-y"]
    elif argtype == "dome_occ":
        args = ["-m", "1", "-f", "BC1_UNORM", "-y"]

    # for some reason it always fails to write if I specify output
    output_path.remove("-o")
    args.extend(output_path)
    start_process(texconv_path, args)


def generate_cubemaps(files, output_path):
    s = ["cube"]
    for filename in files:
        s.append(filename)
    s.extend(output_path)
    s.append("-y")
    start_process(texass_path, s)


def blur_cubes(files):
    if import_status:
        for cube in files:
            img = Image.open(cube)
            processed = img.filter(ImageFilter.GaussianBlur(radius=3))
            processed.save(cube)


if __name__ == "__main__":
    argtype, in_files, out_file = get_args()
    logging.basicConfig(filename=dir_path +
                        "\\cubemapgen.log", level=logging.INFO)

    cubemap_path = fix_paths(out_file)
    print('CUBEMAP PATH', cubemap_path)
    print('IN PATH', in_files)

    if argtype != "dome_occ":
        blur_cubes(in_files)
        generate_cubemaps(in_files, cubemap_path)

    convert_cubemaps(cubemap_path, argtype)
    if argtype == "dome_occ":
        out_file = out_file.replace(".tga", ".DDS")
    move_and_rename_cubemap(out_file)
