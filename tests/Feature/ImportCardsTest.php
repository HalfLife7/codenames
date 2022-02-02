<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ImportCardsTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function itShouldDecodeCardsJsonAndPopulateTheDatabase(): void
    {
        $path = storage_path() . "/cards.json";

        try {
            $json = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException $e) {
        }

        $this->artisan('cards:import');

        $this->assertDatabaseHas('cards', [
            'word' => $json['words'][0]['word'],
            'version' => $json['words'][0]['version']
        ]);
    }
}
