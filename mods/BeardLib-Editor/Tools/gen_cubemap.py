from os import path, rename, remove
from sys import argv, exit
import subprocess, getopt, argparse

dir_path = (path.abspath(path.dirname(__file__)))
texass_path = (path.abspath(path.dirname(__file__)) + "\\texassemble.exe ")
texconv_path = (path.abspath(path.dirname(__file__)) + "\\texconv.exe ")

args = argv[1:]

def get_args(args_v):
    parser = argparse.ArgumentParser(description='Assembles cube faces into a cubemap with a .texture format')
    parser.add_argument("type", help = "first arg has to be either reflect or lights")
    parser.add_argument("-i", help = "imput 6 filenames for each cube face", nargs = "*")
    parser.add_argument("-o", help = "output filename")
    
    args = parser.parse_args(args_v)
    print(args.i)
    print(args.o)
    if args.type != "light" or args.type != "reflect":
        print("test")

    return args.type, args.i, args.o

def move_and_rename_cubemap(cubemap_name):
    cubemap_path = path.abspath("") + "\\"
    cubemap_name_new = o[:-4] + ".texture"
    if not path.isfile(dir_path + "\\temp\\" + cubemap_name_new):
        rename(cubemap_path + o, dir_path + "\\temp\\" + cubemap_name_new)
    if path.isfile(dir_path + "\\temp\\" + cubemap_name):
        remove(dir_path + "\\temp\\" + cubemap_name)

def fix_paths(input_args, output_arg):
    input_paths = []
    if output_arg: 
        output_paths = ["-o", dir_path + "\\temp\\" + output_arg]
    for file in input_args:
        input_paths.append(dir_path + "\\temp\\" + file)
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
    args = ["-m", "10", "-f", "BC2_UNORM", "-y"]
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

if __name__ == "__main__":
    global i, o
    argtype, input, output = get_args(args[:])
    i = input
    o = output
    if argtype == "reflect":
        cube_paths, cubemap_path = fix_paths(input, output)
        generate_cubemaps(cube_paths, cubemap_path)
    elif argtype == "light":
        print("not implemented")