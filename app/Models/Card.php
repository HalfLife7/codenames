<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;

class Card extends \Eloquent
{
    use HasFactory;

    protected $fillable = [
        'word',
        'version'
    ];
}
