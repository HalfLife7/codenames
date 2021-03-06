<?php

namespace App\Http\Controllers\Api\Cards;

use App\Http\Requests\GetCardsRequest;
use App\Models\Card;
use Illuminate\Http\JsonResponse;

class GetCardsController
{

    public function __invoke(GetCardsRequest $request)
    {
        $cards = Card::query()->where('version', '=', 'Original')->get();
        return new JsonResponse($cards->random(25), 200);
    }
}
