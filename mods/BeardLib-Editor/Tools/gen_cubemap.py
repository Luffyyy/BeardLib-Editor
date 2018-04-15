from os import path, rename, remove
from sys import argv, exit
import subprocess, getopt, argparse

import_status = True
try:
    from PIL import Image, ImageFilter
except ImportError:
    print("Pillow module not found! Cubemaps won't be blurred.\n")
else:
    import_status = False

dir_path = (path.abspath(path.dirname(__file__)))
texass_path = (path.abspath(path.dirname(__file__)) + "\\texassemble.exe ")
texconv_path = (path.abspath(path.dirname(__file__)) + "\\texconv.exe ")

args = argv[1:]
temp = "\\temp\\"

def get_args(args_v):
    parser = argparse.ArgumentParser(description='Assembles cube faces into a cubemap with a .texture format')
    parser.add_argument("type", help = "first arg has to be either reflect or lights")
    parser.add_argument("-i", help = "imput 6 filenames for each cube face", nargs = "*")
    parser.add_argument("-o", help = "output filename")
    
    args = parser.parse_args(args_v)
    print(args.i)
    print(args.o)

    return args.type, args.i, args.o

def move_and_rename_cubemap(cubemap_name):
    cubemap_path = path.abspath("") + "\\"
    print(cubemap_path + o)
    cubemap_name_new = o[:-4] + ".texture"
    if not path.isfile(dir_path + temp + cubemap_name_new):
        rename(cubemap_path + o, dir_path + temp + cubemap_name_new)
    if path.isfile(dir_path + temp + cubemap_name):
        remove(dir_path + temp + cubemap_name)
    exit()

def fix_paths(input_args, output_arg):
    input_paths = []
    if output_arg: 
        output_paths = ["-o", dir_path + temp + output_arg]
    for file in input_args:
        input_paths.append(dir_path + temp + file)
    return input_paths, output_paths

def start_process(proc_path, input):
    input.insert(0, proc_path)
    proc = subprocess.Popen(input, stdout=subprocess.PIPE)

    output, _ = proc.communicate()
    output = "".join(map(chr, output))  #needs to be coverted to a string

    print(output)
    #if str.find(output, "ERROR") != -1 and str.find(output, "Failed") != -1:
        #return True
    return True

def convert_cubemaps(output_path):
    if argtyp == "reflect":
        args = ["-m", "10", "-f", "BC2_UNORM", "-y"]
    else:
        args = ["-m", "8", "-f", "BC3_UNORM", "-y"]
    output_path.remove("-o")
    args.extend(output_path)
    if start_process(texconv_path, args):
        move_and_rename_cubemap(o)

def generate_cubemaps(files, output_path):
    s = ["cube"]
    for filename in files:
        s.append(filename)
    s.extend(output_path)
    if start_process(texass_path, s):
        convert_cubemaps(output_path)

def blur_cubes(files):
    if import_status:
        for cube in files:
            img = Image.open(cube)
            img.filter(ImageFilter.GaussianBlur(radius=15))
            img.save(cube)

if __name__ == "__main__":
    global i, o, argtyp
    argtype, input, output = get_args(args[:])
    i = input
    o = output
    argtyp = argtype
    
    cube_paths, cubemap_path = fix_paths(input, output)
    blur_cubes(cube_paths)
    generate_cubemaps(cube_paths, cubemap_path)