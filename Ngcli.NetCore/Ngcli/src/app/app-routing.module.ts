import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

const routes: Routes = [
    { path: 'tex', loadChildren: './tex/tex.module#TexModule' },
    { path: 'd3', loadChildren: './d3/d3.module#D3Module' },
    { path: '**', redirectTo: 'tex', pathMatch: 'full' }
];

@NgModule({
    imports: [RouterModule.forRoot(routes, { useHash: true })],
    exports: [RouterModule]
})
export class AppRoutingModule { }
