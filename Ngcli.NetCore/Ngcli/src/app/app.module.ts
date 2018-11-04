import 'hammerjs';
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { FlexLayoutModule } from '@angular/flex-layout';

import { MaterialModule } from './shared/material/material.module';
import { MathJaxModule } from './shared/math-jax/math-jax.module';
import { ToolbarModule } from './shared/toolbar/toolbar.module';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';

@NgModule({
    declarations: [
        AppComponent
    ],
    imports: [
        BrowserModule, BrowserAnimationsModule, HttpClientModule, FormsModule, FlexLayoutModule,
        AppRoutingModule, MaterialModule, ToolbarModule, MathJaxModule
    ],
    providers: [],
    bootstrap: [AppComponent]
})
export class AppModule { }
