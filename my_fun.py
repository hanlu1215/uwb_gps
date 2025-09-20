#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import matplotlib
matplotlib.rcParams['font.sans-serif'] = ['SimHei']
matplotlib.rcParams['axes.unicode_minus'] = False
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import matplotlib.lines as line1
from matplotlib.widgets import Button
import numpy as np
import csv

def plota():
    global obsX,obsY,obsT,RUN_FLAG
    fig = plt.figure(figsize=(8,6), dpi=80)
    ax = plt.subplot(111,ylim=(-5,5))
    line = line1.Line2D([], [],color='blue', linestyle='-', lw=2)

    def plot_init():
        ax.add_line(line)
        return line,

    def plot_update(i):
        global obsX,obsY,obsT,RUN_FLAG
        if len(obsX) == 0 or len(obsY) == 0:
            return line,
        ax.set_xlim(min(-20,min(obsX)), max(200,max(obsX)))
        ax.set_ylim(min(-20,min(obsY)), max(200,max(obsY)))
        line.set_xdata(np.array(obsX))
        line.set_ydata(np.array(obsY))
        ax.figure.canvas.draw()
        return line,

    def stop_and_save(event):
        global RUN_FLAG
        RUN_FLAG = False
        plt.close(fig)

    btn_ax = fig.add_axes([0.4, 0.92, 0.2, 0.06])
    btn = Button(btn_ax, '停止并保存', color='lightgray', hovercolor='red')
    btn.on_clicked(stop_and_save)

    ani = animation.FuncAnimation(fig, plot_update, init_func=plot_init, frames=1, interval=30, blit=True)
    plt.show()
    RUN_FLAG = False
    print("plota close")


    