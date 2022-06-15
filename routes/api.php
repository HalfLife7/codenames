<?php

use App\Http\Controllers\Api\Cards\GetCardsController;
use App\Http\Controllers\Api\Users\GetUsersController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/
Route::get('/users', GetUsersController::class);

# Cards
Route::get('/cards', GetCardsController::class)->name('cards.index');

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
