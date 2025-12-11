#!/usr/bin/env python

# THIS NEEDS IMPROVEMENT.
import os
import sys
sys.path.append('/home/james/local/workstation/code/shared/img_processing/svg_stack')

from pathlib import Path

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


def slice_compare_view(slicesA,slicesB,direction):
    #
    # ontology_figure(gray_1,gray_2,gray_3,white,slice_m488,slice_m396,slice_m198)
    doc = ss.Document()
    if direction == 'H':
        panels = ss.VBoxLayout()
        panelA = ss.HBoxLayout()
        panelB = ss.HBoxLayout()
    elif direction == 'V':
        panels = ss.HBoxLayout()
        # add some margins
        panels.setSpacing(6)
        panelA = ss.VBoxLayout()
        panelB = ss.VBoxLayout()
    else:
        # just put this here to shut up the IDE warnings.
        panelA = None
        panelB = None
    panels.addLayout(panelA)
    panels.addLayout(panelB)
    
    doc.setLayout(panels)

    for s in slicesA:
        panelA.addSVG(s);
    for s in slicesB:
        panelB.addSVG(s);
    
    return doc

if __name__ == "__main__":
    import argparse
    import re
    parser = argparse.ArgumentParser()


    #parser.add_argument("group1slice1",type=path_exists,help="")
    #parser.add_argument("slices",action='append',nargs=2,metavar=('sliceA','sliceB'),type=path_exists,help="")
    parser.add_argument("-slices",action='append',nargs=2,metavar=('sliceA','sliceB'),type=path_exists,help="")
    parser.add_argument("-d", "--direction","--orientation",type=str,required=True,dest='direction',help='which direciton should we combine, either (H)orizontal or (v)ertical))')
    parser.add_argument("-o", "--output",type=str,required=True,dest='output',help='path to output')
    # logging is intentionally limited. Only exists to help debugging.
    #parser.add_argument("-l",action="store_true",dest='enable_logging',help='enable logging to flock.log in current directory. This is a debugging option.')
    args = parser.parse_args(sys.argv[1:])
    direction='UNSET'
    if re.search(args.direction,'^[(]?[Hh][)]?'):
        direction='H'
    elif re.search(args.direction,'^[(]?[Vv][)]?'):
        direction='V'
    args = parser.parse_args(sys.argv[1:])

    sliceA = [ st[0] for st in args.slices ]
    sliceB = [ st[1] for st in args.slices ]
    #sliceA =[]
    #sliceB =[]
    #for st in args.slices:
    #    sliceA.append(st[0])
    #    sliceB.append(st[1])
    
    show_args=False
    if show_args:
        for e in sliceA:
            tp=Path(e)
            tn=tp.name;
            print(f"{tn}")
        for e in sliceB:
            tp=Path(e)
            tn=tp.name;
            print(f"{tn}")
    
    doc = slice_compare_view(sliceA,sliceB,direction)
    doc.save( args.output )
