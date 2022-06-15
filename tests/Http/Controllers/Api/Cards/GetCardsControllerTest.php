<?php

namespace Tests\Http\Controllers\Api\Cards;

use App\Models\Card;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;


class GetCardsControllerTest extends TestCase
{

    use RefreshDatabase;

    /** @test */
    public function itWillListAllCards()
    {
        $cards = Card::factory()->count(5)->create();

        $this
            ->getJson(route('cards.index'))
            ->assertSuccessful()
            ->assertJson($cards->toArray());
    }
}
