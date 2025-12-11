#!/usr/bin/env python

# THIS NEEDS IMPROVEMENT.
import os
import sys
sys.path.append('/home/james/local/workstation/code/shared/img_processing/svg_stack')

# this code requires svg_stack from
# git url:
#   git@github.com:astraw/svg_stack.git

# doesnt work with conda.
#assert sys.prefix != sys.base_prefix, 'I dont want to run out of a venv'
try:
    import svg_stack as ss
except ImportError:
    # this probably wont work as svg stack is porobably not pip-install ready
    import subprocess
    subprocess.call([sys.executable, '-m', 'pip', 'install', 'svg_stack'])

import svg_stack as ss


"""
doc = ss.Document()

layout1 = ss.HBoxLayout()
layout1.addSVG('red_ball.svg',alignment=ss.AlignTop|ss.AlignHCenter)
layout1.addSVG('blue_triangle.svg',alignment=ss.AlignCenter)

layout2 = ss.VBoxLayout()

layout2.addSVG('red_ball.svg',alignment=ss.AlignCenter)
layout2.addSVG('red_ball.svg',alignment=ss.AlignCenter)
layout2.addSVG('red_ball.svg',alignment=ss.AlignCenter)
layout1.addLayout(layout2)

doc.setLayout(layout1)

doc.save('qt_api_test.svg')
"""

def path_exists(path):
    if os.path.exists(path):
        return path
    else:
        raise argparse.ArgumentTypeError(f"Path {path} does not exist.")

def path_not_exists(path):
    if not os.path.exists(path):
        return path
    else:
        raise argparse.ArgumentTypeError(f"Path {path} does exist.")


def fourGroupThreeSlice(group1slice1,group1slice2,group1slice3,
                              group2slice1,group2slice2,group2slice3,
                              group3slice1,group3slice2,group3slice3,
                              group4slice1,group4slice2,group4slice3):
    #
    # ontology_figure(gray_1,gray_2,gray_3,white,slice_m488,slice_m396,slice_m198)
    doc = ss.Document()
    panels = ss.VBoxLayout()
    panels_top=ss.HBoxLayout()
    panels_bottom=ss.HBoxLayout()

    group1=ss.HBoxLayout()
    group2=ss.HBoxLayout()
    group3=ss.HBoxLayout()
    group4=ss.HBoxLayout()

    panels.addLayout(panels_top)
    panels.addLayout(panels_bottom)
    
    panels_top.addLayout(group1)
    panels_top.addLayout(group2)
    panels_bottom.addLayout(group3)
    panels_bottom.addLayout(group4)
    
    doc.setLayout(panels)

    # add some margins
    panels.setSpacing(6)
    panels_top.setSpacing(6)
    panels_bottom.setSpacing(6)

    group1.addSVG(group1slice1,alignment=ss.AlignVCenter)
    group1.addSVG(group1slice2,alignment=ss.AlignVCenter)
    group1.addSVG(group1slice3,alignment=ss.AlignVCenter)

    group2.addSVG(group2slice1,alignment=ss.AlignVCenter)
    group2.addSVG(group2slice2,alignment=ss.AlignVCenter)
    group2.addSVG(group2slice3,alignment=ss.AlignVCenter)

    group3.addSVG(group3slice1,alignment=ss.AlignVCenter)
    group3.addSVG(group3slice2,alignment=ss.AlignVCenter)
    group3.addSVG(group3slice3,alignment=ss.AlignVCenter)

    group4.addSVG(group4slice1,alignment=ss.AlignVCenter)
    group4.addSVG(group4slice2,alignment=ss.AlignVCenter)
    group4.addSVG(group4slice3,alignment=ss.AlignVCenter)
    
    return doc

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("group1slice1",type=path_exists,help="top-left panel slice 1")
    parser.add_argument("group1slice2",type=path_exists,help="top-left panel slice 2")
    parser.add_argument("group1slice3",type=path_exists,help="top-left panel slice 3")
    
    parser.add_argument("group2slice1",type=path_exists,help="top-right panel slice 1")
    parser.add_argument("group2slice2",type=path_exists,help="top-right panel slice 2")
    parser.add_argument("group2slice3",type=path_exists,help="top-right panel slice 3")
    
    parser.add_argument("group3slice1",type=path_exists,help="bottom-left panel slice 1")
    parser.add_argument("group3slice2",type=path_exists,help="bottom-left panel slice 2")
    parser.add_argument("group3slice3",type=path_exists,help="bottom-left panel slice 3")
    
    parser.add_argument("group4slice1",type=path_exists,help="bottom-left panel slice 1")
    parser.add_argument("group4slice2",type=path_exists,help="bottom-left panel slice 2")
    parser.add_argument("group4slice3",type=path_exists,help="bottom-left panel slice 3")

    parser.add_argument("-o", "--output",type=str,required=True,dest='output',help='path to output')
    # logging is intentionally limited. Only exists to help debugging.
    #parser.add_argument("-l",action="store_true",dest='enable_logging',help='enable logging to flock.log in current directory. This is a debugging option.')
    args = parser.parse_args(sys.argv[1:])
    doc = fourGroupThreeSlice(args.group1slice1,args.group1slice2,args.group1slice3,
                              args.group2slice1,args.group2slice2,args.group2slice3,
                              args.group3slice1,args.group3slice2,args.group3slice3,
                              args.group4slice1,args.group4slice2,args.group4slice3)
    doc.save( args.output )
