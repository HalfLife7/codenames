<?php

namespace App\Console\Commands;

use App\Models\Card;
use Illuminate\Console\Command;
use Illuminate\Support\Collection;
use function strtolower;

class ImportCards extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'cards:import';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Import cards from .json file';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    public function handle(): void
    {
        $path = storage_path() . "/cards.json";
        try {
            $json = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException $e) {
            report($e);
        }

        $cards = Collection::wrap($json["words"]);

        $cards->map(function ($card, $key) {
            Card::updateOrCreate([
                'word' => strtolower($card['word']),
                'version' => $card['version']
            ]);
        });
    }
}
