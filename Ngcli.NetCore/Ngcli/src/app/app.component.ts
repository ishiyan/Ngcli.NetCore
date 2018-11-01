import { Component } from '@angular/core';

import { ToolbarComponent } from './shared/toolbar/toolbar.component';

@Component({
    selector: 'app-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.scss']
})
export class AppComponent {
    title = 'app';

    // {route-id, text} pairs
    public toolbarItems: any = {
        ['tex']: 'TeX',
        ['d3']: 'D3'
    };
}
