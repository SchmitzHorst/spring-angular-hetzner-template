import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ItemService, Item } from '../../services/item.service';

@Component({
  selector: 'app-item-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './item-list.component.html',
  styleUrl: './item-list.component.css'
})
export class ItemListComponent implements OnInit {
  items: Item[] = [];
  newItem: Item = { name: '', description: '' };
  loading = false;
  error = '';

  constructor(private itemService: ItemService) {}

  ngOnInit(): void {
    this.loadItems();
  }

  loadItems(): void {
    this.loading = true;
    this.itemService.getAllItems().subscribe({
      next: (data) => {
        this.items = data;
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Failed to load items';
        this.loading = false;
        console.error(err);
      }
    });
  }

  createItem(): void {
    if (!this.newItem.name.trim()) {
      return;
    }

    this.itemService.createItem(this.newItem).subscribe({
      next: (item) => {
        this.items.push(item);
        this.newItem = { name: '', description: '' };
      },
      error: (err) => {
        this.error = 'Failed to create item';
        console.error(err);
      }
    });
  }

  deleteItem(id: number | undefined): void {
    if (!id) return;

    this.itemService.deleteItem(id).subscribe({
      next: () => {
        this.items = this.items.filter(item => item.id !== id);
      },
      error: (err) => {
        this.error = 'Failed to delete item';
        console.error(err);
      }
    });
  }
}
