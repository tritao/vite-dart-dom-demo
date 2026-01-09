import "./style.css";
import { morphPatch } from "../vendor/morph_patch.js";
import "../vendor/floating_ui_bridge.js";
import "./labs_main.dart";

globalThis.morphPatch = morphPatch;

