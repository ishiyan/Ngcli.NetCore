import { Component, OnInit, ElementRef } from '@angular/core';
import { MatSelectChange, /*MatCheckboxChange,*/ MatSlideToggleChange } from '@angular/material';
import * as d3 from 'd3';

import * as hilbert from '../hilbert';

@Component({
    selector: 'app-hilbert-curve',
    templateUrl: './hilbert-curve.component.html',
    styleUrls: ['./hilbert-curve.component.scss']
})
export class HilbertCurveComponent implements OnInit {
    public colors = false;
    public selectedLevel = '6';
    private level = 6;
    private level10 = Math.pow(2, this.level); // 1 << this.level
    private level102 = Math.pow(2, this.level * 2); // 1 << (this.level * 2)
    private readonly w = 500;
    private readonly x = d3.scaleLinear().domain([0, this.level10]).range([0, this.w]);
    private line: any;
    private g: any;

    constructor(private element: ElementRef) {
    }

    selectionChanged(event: MatSelectChange) {
        this.level = +event.value;
        this.level10 = Math.pow(2, this.level); // 1 << this.level
        this.level102 = Math.pow(2, this.level * 2); // 1 << (this.level * 2)
        this.redraw();
    }

    colorChanged(event: MatSlideToggleChange /*MatCheckboxChange*/) {
        this.colors = event.checked;
        this.redraw();
    }

    private redraw() {
        this.x.domain([-.5, this.level10]);
        const curve = d3.range(this.level102).map(i => hilbert.d2xy(this.level, i));
        this.g.select('path').attr('d', this.line(curve));
        const square = this.g.selectAll('rect').data(this.colors ? curve : []);
        square.enter().append('rect');
        square.exit().remove();
        this.g.selectAll('rect')
            .style('fill', (d, i) => d3.hsl(Math.floor(i * 360 / this.level102), 1, .5).rgb())
            // .style('fill', (d, i) => d3.hsl(~~(i * 360 / this.level102), 1, .5).rgb())
            .attr('x', d => this.x(d[0] - .5)).attr('y', d => this.x(d[1] - .5))
            .attr('width', this.x(1) - this.x(0) + 1).attr('height', this.x(1) - this.x(0) + 1);
    }

    ngOnInit() {
        // why can't it find the svg element? have to use svg id instead
        this.g = d3.select(this.element.nativeElement).select('#d3-hilbert-curve').attr('width', this.w).attr('height', this.w)
            .append('g');
        this.g.append('path').attr('d', 'M0,0').style('fill', 'none').style('stroke', 'black');
        this.line = d3.line().x(d => this.x(d[0])).y(d => this.x(d[1]));
        this.redraw();
    }
}
