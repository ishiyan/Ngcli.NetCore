import {Directive, ElementRef, Input, OnChanges, OnInit} from '@angular/core';
import 'mathjax';

@Directive({
  selector: '[appMathJax]'
})
export class MathJaxDirective implements OnInit, OnChanges {
  @Input() appMathJax = '';
  constructor(private element: ElementRef) {
  }

  ngOnInit() {
    this.element.nativeElement.innerHTML = this.appMathJax;
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, this.element.nativeElement]);
  }

  ngOnChanges() {
    this.element.nativeElement.innerHTML = this.appMathJax;
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, this.element.nativeElement]);
  }
}
