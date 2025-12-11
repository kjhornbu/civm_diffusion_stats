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


def ontology_figure(onto_1,onto_2,onto_3,onto_4,slice_1,slice_2,slice_3):
    #
    # ontology_figure(gray_1,gray_2,gray_3,white,slice_m488,slice_m396,slice_m198)
    doc = ss.Document()
    panels = ss.HBoxLayout()
    panel_left=ss.HBoxLayout()
    panel_col1=ss.VBoxLayout()
    panel_col2=ss.VBoxLayout()
    panel_right=ss.HBoxLayout()

    panel_left.addLayout(panel_col1)
    panel_left.addLayout(panel_col2)
    panels.addLayout(panel_left)
    panels.addLayout(panel_right)
    doc.setLayout(panels)

    # add some margins
    panels.setSpacing(6)
    panel_left.setSpacing(6)
    panel_right.setSpacing(6)
    panel_col2.setSpacing(6)

    # 3==top, 1==bottom, 2=middle(dur)
    panel_col1.addSVG(slice_3,alignment=ss.AlignTop|ss.AlignHCenter)
    panel_col1.addSVG(slice_1,alignment=ss.AlignBottom|ss.AlignHCenter)

    panel_col2.addSVG(slice_2,alignment=ss.AlignTop|ss.AlignHCenter)
    panel_col2.addSVG(onto_4,alignment=ss.AlignCenter)

    panel_right.addSVG(onto_1,alignment=ss.AlignVCenter|ss.AlignLeft)
    panel_right.addSVG(onto_2,alignment=ss.AlignVCenter|ss.AlignHCenter)
    panel_right.addSVG(onto_3,alignment=ss.AlignVCenter|ss.AlignRight)

    return doc

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("gray1",type=path_exists,help="Ontology right panel 1 (gray1)")
    parser.add_argument("gray2",type=path_exists,help="Ontology right panel 2 (gray2)")
    parser.add_argument("gray3",type=path_exists,help="Ontology right panel 3 (gray3)")
    parser.add_argument("white",type=path_exists,help="Ontology left panel (white)")
    parser.add_argument("slice1",type=path_exists,help="Slice left panel lowest")
    parser.add_argument("slice2",type=path_exists,help="Slice left panel middle")
    parser.add_argument("slice3",type=path_exists,help="Slice left panel highest")
    parser.add_argument("-o", "--output",type=str,required=True,dest='output',help='path to output')
    # logging is intentionally limited. Only exists to help debugging.
    #parser.add_argument("-l",action="store_true",dest='enable_logging',help='enable logging to flock.log in current directory. This is a debugging option.')
    args = parser.parse_args(sys.argv[1:])
    doc = ontology_figure(args.gray1,args.gray2,args.gray3,args.white,args.slice1,args.slice2,args.slice3)
    doc.save( args.output )
